-- Retail 360 | R3 | Nuestro ETL: pasa los datos de la operación (oltp) al modelo de análisis (dwh).
--
-- Se usa igual que el del profesor:  CALL dwh.cargar_retail360();
-- Este archivo solo CREA el procedimiento; la carga se hace con sql/05b_ejecutar_etl.sql.
-- Prerrequisitos: sql/01, 02, 04 y nuestro 02_DWH/ajustes_dwh_grupo.sql.
--
-- Lo organizamos en los 5 pasos de la infografía del curso:
--   1. Extraer           -> vistas etl.v_* que leen la operación tal como está.
--   2. Limpiar/validar   -> etl.revisar_origen(): si algo no cuadra, la carga no arranca.
--   3. Reglas de negocio -> etl.montos_linea(): una sola forma de calcular bruto, descuento, neto e IVA.
--   4. Granularidad      -> cada vista entrega una fila por evento (línea, movimiento, meta o pago).
--   5. Cargar y revisar  -> etl.cargar_dimensiones(), etl.cargar_hechos() y etl.conciliar().
--
-- Se puede correr las veces que se quiera: si nada cambió en la operación, no cambia nada
-- en el modelo (ON CONFLICT + solo se reescribe la fila cuando algún dato es distinto).

CREATE SCHEMA IF NOT EXISTS etl;

-- =====================================================================================
-- PASO 3. Reglas de negocio: cálculo de los valores de una línea.
-- Mismo redondeo que usa la guía: primero el bruto, luego el descuento sobre el bruto,
-- el neto es bruto - descuento y el IVA se calcula sobre el neto. Todo con NUMERIC.
-- =====================================================================================
CREATE OR REPLACE FUNCTION etl.montos_linea(
    p_precio numeric, p_cantidad integer, p_descuento_pct numeric, p_impuesto_pct numeric,
    OUT bruto numeric, OUT descuento numeric, OUT neto numeric, OUT impuesto numeric)
LANGUAGE sql IMMUTABLE
AS $$
    SELECT b.bruto, b.descuento, b.bruto - b.descuento,
           round((b.bruto - b.descuento) * p_impuesto_pct, 2)
    FROM (SELECT round(p_precio * p_cantidad, 2) AS bruto,
                 round(round(p_precio * p_cantidad, 2) * p_descuento_pct, 2) AS descuento) b
$$;

-- =====================================================================================
-- PASOS 1 y 4. Extraer con la granularidad de cada hecho.
-- Las vistas usan las llaves de la operación (ids); el cambio a llaves del modelo
-- (sucursal_key, cliente_key, etc.) se hace al cargar.
-- =====================================================================================

-- Ventas: una fila por línea de factura (positiva, fecha de la factura)
-- y una fila por línea de nota crédito (negativa, fecha de la nota). La factura original no se toca.
CREATE OR REPLACE VIEW etl.v_venta AS
SELECT 'FACTURA'::text AS tipo_evento, fd.factura_detalle_id AS linea_origen_id, f.factura_id,
       f.fecha_factura AS fecha_evento, p.sucursal_id, p.cliente_id, p.vendedor_id, fd.producto_id,
       fd.cantidad AS unidades, m.bruto AS valor_bruto, m.descuento, m.neto AS venta_neta,
       round(fd.costo_unitario * fd.cantidad, 2) AS costo_venta, m.impuesto,
       m.neto + m.impuesto AS valor_facturado_con_impuesto
FROM oltp.factura_detalle fd
JOIN oltp.factura f ON f.factura_id = fd.factura_id
JOIN oltp.pedido p  ON p.pedido_id = f.pedido_id
CROSS JOIN LATERAL etl.montos_linea(fd.precio_unitario, fd.cantidad, fd.descuento_pct, fd.impuesto_pct) m
WHERE f.estado = 'EMITIDA'
UNION ALL
SELECT 'NOTA_CREDITO', nd.nota_detalle_id, f.factura_id,
       nc.fecha_nota, p.sucursal_id, p.cliente_id, p.vendedor_id, fd.producto_id,
       -nd.cantidad, -m.bruto, -m.descuento, -m.neto,
       -round(fd.costo_unitario * nd.cantidad, 2), -m.impuesto,
       -(m.neto + m.impuesto)
FROM oltp.nota_credito_detalle nd
JOIN oltp.nota_credito nc    ON nc.nota_id = nd.nota_id
JOIN oltp.factura_detalle fd ON fd.factura_detalle_id = nd.factura_detalle_id
JOIN oltp.factura f          ON f.factura_id = nc.factura_id
JOIN oltp.pedido p           ON p.pedido_id = f.pedido_id
-- La devolución usa el precio, descuento e IVA de la línea que se vendió.
CROSS JOIN LATERAL etl.montos_linea(fd.precio_unitario, nd.cantidad, fd.descuento_pct, fd.impuesto_pct) m
WHERE f.estado = 'EMITIDA';

-- Inventario: una fila por movimiento. No se convierte en ventas.
CREATE OR REPLACE VIEW etl.v_inventario AS
SELECT movimiento_id, fecha_movimiento, bodega_id, producto_id, tipo, cantidad_delta
FROM oltp.movimiento_inventario;

-- Metas: una fila por vendedor, sucursal y mes (siempre el día 1).
CREATE OR REPLACE VIEW etl.v_meta AS
SELECT meta_id, mes, vendedor_id, sucursal_id, monto_meta
FROM oltp.meta_mensual;

-- Recaudo: una fila por pago, con la fecha del pago (no la de la factura).
-- Sucursal, cliente y vendedor salen del pedido de la factura pagada.
CREATE OR REPLACE VIEW etl.v_recaudo AS
SELECT pg.pago_id, pg.factura_id, pg.fecha_pago, p.sucursal_id, p.cliente_id, p.vendedor_id, pg.monto
FROM oltp.pago pg
JOIN oltp.factura f ON f.factura_id = pg.factura_id
JOIN oltp.pedido p  ON p.pedido_id = f.pedido_id
WHERE f.estado = 'EMITIDA';

-- =====================================================================================
-- PASO 2. Limpiar y validar el origen ANTES de cargar.
-- Solo revisa cosas que la base de la operación no impide sola (las demás ya las cuidan
-- los CHECK y las llaves foráneas). "detiene" = si aparece, la carga no se hace.
-- =====================================================================================
CREATE OR REPLACE FUNCTION etl.revisar_origen()
RETURNS TABLE (control text, filas bigint, detiene boolean)
LANGUAGE sql STABLE
AS $$
    SELECT 'Factura de un pedido que no está FACTURADO', count(*), true
    FROM oltp.factura f JOIN oltp.pedido p ON p.pedido_id = f.pedido_id
    WHERE p.estado <> 'FACTURADO'
  UNION ALL
    SELECT 'Línea de factura distinta a su línea de pedido', count(*), true
    FROM oltp.factura_detalle fd
    JOIN oltp.pedido_detalle pd ON pd.pedido_detalle_id = fd.pedido_detalle_id
    JOIN oltp.factura f ON f.factura_id = fd.factura_id
    WHERE pd.producto_id <> fd.producto_id OR pd.cantidad <> fd.cantidad OR pd.pedido_id <> f.pedido_id
  UNION ALL
    SELECT 'Nota crédito que devuelve una línea de otra factura', count(*), true
    FROM oltp.nota_credito_detalle nd
    JOIN oltp.nota_credito nc ON nc.nota_id = nd.nota_id
    JOIN oltp.factura_detalle fd ON fd.factura_detalle_id = nd.factura_detalle_id
    WHERE fd.factura_id <> nc.factura_id
  UNION ALL
    SELECT 'Línea devuelta más veces de lo que se vendió', count(*), true
    FROM (SELECT nd.factura_detalle_id, sum(nd.cantidad) AS devuelto
          FROM oltp.nota_credito_detalle nd GROUP BY 1) d
    JOIN oltp.factura_detalle fd ON fd.factura_detalle_id = d.factura_detalle_id
    WHERE d.devuelto > fd.cantidad
  UNION ALL
    SELECT 'Nota crédito con fecha antes de su factura', count(*), true
    FROM oltp.nota_credito nc JOIN oltp.factura f ON f.factura_id = nc.factura_id
    WHERE nc.fecha_nota < f.fecha_factura
  UNION ALL
    SELECT 'Pago con fecha antes de su factura', count(*), true
    FROM oltp.pago pg JOIN oltp.factura f ON f.factura_id = pg.factura_id
    WHERE pg.fecha_pago < f.fecha_factura
  UNION ALL
    SELECT 'Factura con más pagos que su valor total', count(*), true
    FROM (SELECT factura_id, sum(monto) AS pagado FROM oltp.pago GROUP BY 1) pg
    JOIN (SELECT factura_id, sum(valor_facturado_con_impuesto) AS total
          FROM etl.v_venta WHERE tipo_evento = 'FACTURA' GROUP BY 1) t USING (factura_id)
    WHERE pg.pagado > t.total
  UNION ALL
    -- Que una factura esté anulada no es un error, pero queda por fuera del modelo: se avisa.
    SELECT 'Facturas ANULADAS (no se cargan)', count(*), false
    FROM oltp.factura WHERE estado = 'ANULADA'
$$;

-- =====================================================================================
-- PASO 5a. Cargar dimensiones (primero, porque los hechos las necesitan).
-- Cambios tipo 1: si un nombre o una ciudad cambia en la operación, se sobrescribe.
-- Devuelve un texto corto con cuántas filas nuevas y cuántas actualizadas hubo.
-- (xmax = 0 en RETURNING significa que la fila se insertó; si no, se actualizó.)
-- =====================================================================================
CREATE OR REPLACE FUNCTION etl.cargar_dimensiones()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_desde date; v_hasta date;
    n int; a int; v_resumen text := '';
BEGIN
    -- Fecha: desde el 1 de enero del primer año con datos hasta el 31 de diciembre del último
    -- (incluye vencimientos). Nombres en español fijos para no depender del idioma de Windows.
    SELECT date_trunc('year', min(d))::date,
           (date_trunc('year', max(d)) + interval '1 year - 1 day')::date
      INTO v_desde, v_hasta
    FROM (SELECT fecha_factura AS d FROM oltp.factura
          UNION ALL SELECT fecha_vencimiento FROM oltp.factura
          UNION ALL SELECT fecha_nota FROM oltp.nota_credito
          UNION ALL SELECT fecha_pago FROM oltp.pago
          UNION ALL SELECT fecha_movimiento FROM oltp.movimiento_inventario
          UNION ALL SELECT mes FROM oltp.meta_mensual) x;

    WITH r AS (
        INSERT INTO dwh.dim_fecha AS t
            (fecha_key, fecha, anio, mes_num, mes_inicio, trimestre, anio_mes, dia, nombre_dia, nombre_mes)
        SELECT to_char(g.d, 'YYYYMMDD')::int, g.d::date, extract(year FROM g.d)::int,
               extract(month FROM g.d)::int, date_trunc('month', g.d)::date,
               extract(quarter FROM g.d)::int, to_char(g.d, 'YYYY-MM'), extract(day FROM g.d)::int,
               (ARRAY['lunes','martes','miércoles','jueves','viernes','sábado','domingo'])[extract(isodow FROM g.d)::int],
               (ARRAY['enero','febrero','marzo','abril','mayo','junio','julio','agosto',
                      'septiembre','octubre','noviembre','diciembre'])[extract(month FROM g.d)::int]
        FROM generate_series(v_desde, v_hasta, interval '1 day') AS g(d)
        ON CONFLICT (fecha_key) DO UPDATE SET
            dia = EXCLUDED.dia, nombre_dia = EXCLUDED.nombre_dia, nombre_mes = EXCLUDED.nombre_mes
        WHERE (t.dia, t.nombre_dia, t.nombre_mes)
              IS DISTINCT FROM (EXCLUDED.dia, EXCLUDED.nombre_dia, EXCLUDED.nombre_mes)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format('fecha +%s ~%s', n, a);

    -- Sucursal. La región no viene en los datos: se deduce de la ciudad.
    WITH r AS (
        INSERT INTO dwh.dim_sucursal AS t (sucursal_id, nombre, ciudad, region)
        SELECT sucursal_id, nombre, ciudad,
               CASE WHEN ciudad IN ('Manizales','Pereira','Armenia') THEN 'Eje Cafetero'
                    WHEN ciudad = 'Medellín' THEN 'Antioquia'
                    ELSE 'Sin región' END
        FROM oltp.sucursal
        ON CONFLICT (sucursal_id) DO UPDATE SET
            nombre = EXCLUDED.nombre, ciudad = EXCLUDED.ciudad, region = EXCLUDED.region
        WHERE (t.nombre, t.ciudad, t.region) IS DISTINCT FROM (EXCLUDED.nombre, EXCLUDED.ciudad, EXCLUDED.region)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | sucursal +%s ~%s', n, a);

    -- Bodega, enlazada a su sucursal (la central queda sin sucursal).
    WITH r AS (
        INSERT INTO dwh.dim_bodega AS t (bodega_id, nombre, tipo, sucursal_id, sucursal_key)
        SELECT b.bodega_id, b.nombre, b.tipo, b.sucursal_id, s.sucursal_key
        FROM oltp.bodega b LEFT JOIN dwh.dim_sucursal s ON s.sucursal_id = b.sucursal_id
        ON CONFLICT (bodega_id) DO UPDATE SET
            nombre = EXCLUDED.nombre, tipo = EXCLUDED.tipo,
            sucursal_id = EXCLUDED.sucursal_id, sucursal_key = EXCLUDED.sucursal_key
        WHERE (t.nombre, t.tipo, t.sucursal_id, t.sucursal_key)
              IS DISTINCT FROM (EXCLUDED.nombre, EXCLUDED.tipo, EXCLUDED.sucursal_id, EXCLUDED.sucursal_key)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | bodega +%s ~%s', n, a);

    -- Cliente, con sus días de crédito.
    WITH r AS (
        INSERT INTO dwh.dim_cliente AS t (cliente_id, nombre, segmento, ciudad, plazo_credito_dias)
        SELECT cliente_id, nombre, segmento, ciudad, plazo_credito_dias FROM oltp.cliente
        ON CONFLICT (cliente_id) DO UPDATE SET
            nombre = EXCLUDED.nombre, segmento = EXCLUDED.segmento, ciudad = EXCLUDED.ciudad,
            plazo_credito_dias = EXCLUDED.plazo_credito_dias
        WHERE (t.nombre, t.segmento, t.ciudad, t.plazo_credito_dias)
              IS DISTINCT FROM (EXCLUDED.nombre, EXCLUDED.segmento, EXCLUDED.ciudad, EXCLUDED.plazo_credito_dias)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | cliente +%s ~%s', n, a);

    -- Vendedor, con su sucursal actual y fecha de ingreso.
    -- (Si un vendedor se cambia de sucursal, aquí se sobrescribe. La versión con historia
    --  -tipo 2- es la propuesta que dejamos en 02_DWH/modelo_dimensional.md.)
    WITH r AS (
        INSERT INTO dwh.dim_vendedor AS t (vendedor_id, nombre, sucursal_actual_id, sucursal_key, fecha_ingreso)
        SELECT v.vendedor_id, v.nombre, v.sucursal_id, s.sucursal_key, v.fecha_ingreso
        FROM oltp.vendedor v JOIN dwh.dim_sucursal s ON s.sucursal_id = v.sucursal_id
        ON CONFLICT (vendedor_id) DO UPDATE SET
            nombre = EXCLUDED.nombre, sucursal_actual_id = EXCLUDED.sucursal_actual_id,
            sucursal_key = EXCLUDED.sucursal_key, fecha_ingreso = EXCLUDED.fecha_ingreso
        WHERE (t.nombre, t.sucursal_actual_id, t.sucursal_key, t.fecha_ingreso)
              IS DISTINCT FROM (EXCLUDED.nombre, EXCLUDED.sucursal_actual_id, EXCLUDED.sucursal_key, EXCLUDED.fecha_ingreso)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | vendedor +%s ~%s', n, a);

    -- Producto, con el nombre de su categoría, costo estándar y precio de lista.
    WITH r AS (
        INSERT INTO dwh.dim_producto AS t (producto_id, nombre, categoria_id, categoria, costo_estandar, precio_lista)
        SELECT p.producto_id, p.nombre, p.categoria_id, c.nombre, p.costo_estandar, p.precio_lista
        FROM oltp.producto p JOIN oltp.categoria c ON c.categoria_id = p.categoria_id
        ON CONFLICT (producto_id) DO UPDATE SET
            nombre = EXCLUDED.nombre, categoria_id = EXCLUDED.categoria_id, categoria = EXCLUDED.categoria,
            costo_estandar = EXCLUDED.costo_estandar, precio_lista = EXCLUDED.precio_lista
        WHERE (t.nombre, t.categoria_id, t.categoria, t.costo_estandar, t.precio_lista)
              IS DISTINCT FROM (EXCLUDED.nombre, EXCLUDED.categoria_id, EXCLUDED.categoria,
                                EXCLUDED.costo_estandar, EXCLUDED.precio_lista)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | producto +%s ~%s', n, a);

    RETURN v_resumen;
END;
$$;

-- =====================================================================================
-- PASO 5b. Cargar los 4 hechos. Cada uno con su propia granularidad y su propia fecha.
-- =====================================================================================
CREATE OR REPLACE FUNCTION etl.cargar_hechos()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE n int; a int; v_resumen text := '';
BEGIN
    -- Ventas y notas crédito.
    WITH r AS (
        INSERT INTO dwh.fact_venta AS t
            (tipo_evento, linea_origen_id, factura_id, fecha_key, sucursal_key, cliente_key, vendedor_key,
             producto_key, unidades, valor_bruto, descuento, venta_neta, costo_venta, impuesto,
             valor_facturado_con_impuesto)
        SELECT v.tipo_evento, v.linea_origen_id, v.factura_id, to_char(v.fecha_evento, 'YYYYMMDD')::int,
               ds.sucursal_key, dc.cliente_key, dv.vendedor_key, dp.producto_key,
               v.unidades, v.valor_bruto, v.descuento, v.venta_neta, v.costo_venta, v.impuesto,
               v.valor_facturado_con_impuesto
        FROM etl.v_venta v
        JOIN dwh.dim_sucursal ds ON ds.sucursal_id = v.sucursal_id
        JOIN dwh.dim_cliente  dc ON dc.cliente_id  = v.cliente_id
        JOIN dwh.dim_vendedor dv ON dv.vendedor_id = v.vendedor_id
        JOIN dwh.dim_producto dp ON dp.producto_id = v.producto_id
        ON CONFLICT (tipo_evento, linea_origen_id) DO UPDATE SET
            factura_id = EXCLUDED.factura_id, fecha_key = EXCLUDED.fecha_key,
            sucursal_key = EXCLUDED.sucursal_key, cliente_key = EXCLUDED.cliente_key,
            vendedor_key = EXCLUDED.vendedor_key, producto_key = EXCLUDED.producto_key,
            unidades = EXCLUDED.unidades, valor_bruto = EXCLUDED.valor_bruto, descuento = EXCLUDED.descuento,
            venta_neta = EXCLUDED.venta_neta, costo_venta = EXCLUDED.costo_venta, impuesto = EXCLUDED.impuesto,
            valor_facturado_con_impuesto = EXCLUDED.valor_facturado_con_impuesto
        WHERE (t.factura_id, t.fecha_key, t.sucursal_key, t.cliente_key, t.vendedor_key, t.producto_key,
               t.unidades, t.valor_bruto, t.descuento, t.venta_neta, t.costo_venta, t.impuesto,
               t.valor_facturado_con_impuesto)
              IS DISTINCT FROM
              (EXCLUDED.factura_id, EXCLUDED.fecha_key, EXCLUDED.sucursal_key, EXCLUDED.cliente_key,
               EXCLUDED.vendedor_key, EXCLUDED.producto_key, EXCLUDED.unidades, EXCLUDED.valor_bruto,
               EXCLUDED.descuento, EXCLUDED.venta_neta, EXCLUDED.costo_venta, EXCLUDED.impuesto,
               EXCLUDED.valor_facturado_con_impuesto)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format('venta +%s ~%s', n, a);

    -- Movimientos de inventario.
    WITH r AS (
        INSERT INTO dwh.fact_movimiento_inventario AS t
            (movimiento_id, fecha_key, bodega_key, producto_key, tipo, cantidad_delta)
        SELECT m.movimiento_id, to_char(m.fecha_movimiento, 'YYYYMMDD')::int, b.bodega_key, p.producto_key,
               m.tipo, m.cantidad_delta
        FROM etl.v_inventario m
        JOIN dwh.dim_bodega b   ON b.bodega_id = m.bodega_id
        JOIN dwh.dim_producto p ON p.producto_id = m.producto_id
        ON CONFLICT (movimiento_id) DO UPDATE SET
            fecha_key = EXCLUDED.fecha_key, bodega_key = EXCLUDED.bodega_key,
            producto_key = EXCLUDED.producto_key, tipo = EXCLUDED.tipo, cantidad_delta = EXCLUDED.cantidad_delta
        WHERE (t.fecha_key, t.bodega_key, t.producto_key, t.tipo, t.cantidad_delta)
              IS DISTINCT FROM (EXCLUDED.fecha_key, EXCLUDED.bodega_key, EXCLUDED.producto_key,
                                EXCLUDED.tipo, EXCLUDED.cantidad_delta)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | inventario +%s ~%s', n, a);

    -- Metas mensuales (la fecha es el día 1 del mes).
    WITH r AS (
        INSERT INTO dwh.fact_meta AS t (meta_id, mes_fecha_key, sucursal_key, vendedor_key, monto_meta)
        SELECT m.meta_id, to_char(m.mes, 'YYYYMMDD')::int, s.sucursal_key, v.vendedor_key, m.monto_meta
        FROM etl.v_meta m
        JOIN dwh.dim_sucursal s ON s.sucursal_id = m.sucursal_id
        JOIN dwh.dim_vendedor v ON v.vendedor_id = m.vendedor_id
        ON CONFLICT (meta_id) DO UPDATE SET
            mes_fecha_key = EXCLUDED.mes_fecha_key, sucursal_key = EXCLUDED.sucursal_key,
            vendedor_key = EXCLUDED.vendedor_key, monto_meta = EXCLUDED.monto_meta
        WHERE (t.mes_fecha_key, t.sucursal_key, t.vendedor_key, t.monto_meta)
              IS DISTINCT FROM (EXCLUDED.mes_fecha_key, EXCLUDED.sucursal_key, EXCLUDED.vendedor_key,
                                EXCLUDED.monto_meta)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | meta +%s ~%s', n, a);

    -- Recaudos (pagos).
    WITH r AS (
        INSERT INTO dwh.fact_recaudo AS t
            (pago_id, factura_id, fecha_key, sucursal_key, cliente_key, vendedor_key, monto_recaudado)
        SELECT r.pago_id, r.factura_id, to_char(r.fecha_pago, 'YYYYMMDD')::int,
               s.sucursal_key, c.cliente_key, v.vendedor_key, r.monto
        FROM etl.v_recaudo r
        JOIN dwh.dim_sucursal s ON s.sucursal_id = r.sucursal_id
        JOIN dwh.dim_cliente  c ON c.cliente_id  = r.cliente_id
        JOIN dwh.dim_vendedor v ON v.vendedor_id = r.vendedor_id
        ON CONFLICT (pago_id) DO UPDATE SET
            factura_id = EXCLUDED.factura_id, fecha_key = EXCLUDED.fecha_key,
            sucursal_key = EXCLUDED.sucursal_key, cliente_key = EXCLUDED.cliente_key,
            vendedor_key = EXCLUDED.vendedor_key, monto_recaudado = EXCLUDED.monto_recaudado
        WHERE (t.factura_id, t.fecha_key, t.sucursal_key, t.cliente_key, t.vendedor_key, t.monto_recaudado)
              IS DISTINCT FROM (EXCLUDED.factura_id, EXCLUDED.fecha_key, EXCLUDED.sucursal_key,
                                EXCLUDED.cliente_key, EXCLUDED.vendedor_key, EXCLUDED.monto_recaudado)
        RETURNING (xmax = 0) AS nueva)
    SELECT count(*) FILTER (WHERE nueva), count(*) FILTER (WHERE NOT nueva) INTO n, a FROM r;
    v_resumen := v_resumen || format(' | recaudo +%s ~%s', n, a);

    RETURN v_resumen;
END;
$$;

-- =====================================================================================
-- PASO 5c. Conciliar: comparar lo que hay en la operación con lo que quedó en el modelo.
-- Si una fila se pierde en un JOIN o queda una fila de más, aquí se nota.
-- =====================================================================================
CREATE OR REPLACE FUNCTION etl.conciliar()
RETURNS TABLE (control text, origen numeric, modelo numeric, diferencia numeric)
LANGUAGE sql STABLE
AS $$
    WITH c AS (
        SELECT 'Filas de venta (facturas + notas)' AS control,
               (SELECT count(*) FROM etl.v_venta)::numeric AS origen,
               (SELECT count(*) FROM dwh.fact_venta)::numeric AS modelo
        UNION ALL
        SELECT 'Venta neta (sin IVA)',
               (SELECT coalesce(sum(venta_neta), 0) FROM etl.v_venta),
               (SELECT coalesce(sum(venta_neta), 0) FROM dwh.fact_venta)
        UNION ALL
        SELECT 'Costo de venta',
               (SELECT coalesce(sum(costo_venta), 0) FROM etl.v_venta),
               (SELECT coalesce(sum(costo_venta), 0) FROM dwh.fact_venta)
        UNION ALL
        SELECT 'Movimientos de inventario',
               (SELECT count(*) FROM etl.v_inventario), (SELECT count(*) FROM dwh.fact_movimiento_inventario)
        UNION ALL
        SELECT 'Unidades en inventario (saldo)',
               (SELECT coalesce(sum(cantidad_delta), 0) FROM etl.v_inventario),
               (SELECT coalesce(sum(cantidad_delta), 0) FROM dwh.fact_movimiento_inventario)
        UNION ALL
        SELECT 'Metas', (SELECT count(*) FROM etl.v_meta), (SELECT count(*) FROM dwh.fact_meta)
        UNION ALL
        SELECT 'Valor de las metas',
               (SELECT coalesce(sum(monto_meta), 0) FROM etl.v_meta),
               (SELECT coalesce(sum(monto_meta), 0) FROM dwh.fact_meta)
        UNION ALL
        SELECT 'Pagos', (SELECT count(*) FROM etl.v_recaudo), (SELECT count(*) FROM dwh.fact_recaudo)
        UNION ALL
        SELECT 'Valor recaudado',
               (SELECT coalesce(sum(monto), 0) FROM etl.v_recaudo),
               (SELECT coalesce(sum(monto_recaudado), 0) FROM dwh.fact_recaudo)
    )
    SELECT control, origen, modelo, origen - modelo FROM c
$$;

-- =====================================================================================
-- Procedimiento principal (el "contrato" del profesor). Une los 5 pasos y deja la bitácora.
-- No hace COMMIT por dentro: así funciona también dentro de BEGIN ... ROLLBACK
-- (scripts 12 y 13 del profesor). Si algo falla, se deshace la carga completa.
-- =====================================================================================
CREATE OR REPLACE PROCEDURE dwh.cargar_retail360()
LANGUAGE plpgsql
AS $$
DECLARE
    v_corrida bigint;
    v_problemas text;
    v_dims text;
    v_hechos text;
    v_descuadre text;
BEGIN
    INSERT INTO dwh.bitacora_carga (estado, mensaje)
    VALUES ('EN_CURSO', 'Inicio de carga (ETL del grupo)')
    RETURNING corrida_id INTO v_corrida;

    -- Paso 2: si el origen tiene problemas graves, no se carga nada.
    SELECT string_agg(control || ': ' || filas, '; ')
      INTO v_problemas
    FROM etl.revisar_origen() WHERE detiene AND filas > 0;
    IF v_problemas IS NOT NULL THEN
        RAISE EXCEPTION 'Carga detenida, el origen tiene problemas -> %', v_problemas;
    END IF;

    -- Pasos 3, 4 y 5: dimensiones primero, luego los hechos.
    v_dims   := etl.cargar_dimensiones();
    v_hechos := etl.cargar_hechos();

    -- Revisión final: origen y modelo deben quedar iguales, al centavo.
    SELECT string_agg(control || ' (origen ' || origen || ', modelo ' || modelo || ')', '; ')
      INTO v_descuadre
    FROM etl.conciliar() WHERE diferencia <> 0;
    IF v_descuadre IS NOT NULL THEN
        RAISE EXCEPTION 'Carga deshecha, el modelo no cuadra con el origen -> %', v_descuadre;
    END IF;

    UPDATE dwh.bitacora_carga SET
        finalizado         = clock_timestamp(),
        estado             = 'OK',
        filas_fact_venta   = (SELECT count(*) FROM dwh.fact_venta),
        filas_fact_inv     = (SELECT count(*) FROM dwh.fact_movimiento_inventario),
        filas_fact_meta    = (SELECT count(*) FROM dwh.fact_meta),
        filas_fact_recaudo = (SELECT count(*) FROM dwh.fact_recaudo),
        -- "+" = filas nuevas, "~" = filas que cambiaron. En una segunda carga sin cambios todo da 0.
        mensaje            = 'OK. Dimensiones: ' || v_dims || '. Hechos: ' || v_hechos || '. Cuadra con el origen.'
    WHERE corrida_id = v_corrida;

    RAISE NOTICE 'Carga % OK | %', v_corrida, v_hechos;
END;
$$;

COMMENT ON PROCEDURE dwh.cargar_retail360() IS
    'ETL del grupo Retail 360: valida el origen, carga dimensiones y hechos con ON CONFLICT y concilia contra la operación.';
