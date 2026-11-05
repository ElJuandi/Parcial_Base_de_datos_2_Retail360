-- Retail 360 | R4 | Nuestras respuestas a los 12 retos de sql/11_retos_consultas_estudiante.sql
-- Solo consulta: no crea ni cambia datos. Necesita R3 cargado y los scripts 07 y 10 del profesor.
-- Fecha de corte del caso: 30 de septiembre de 2026.
-- Montos en pesos, sin IVA, salvo donde se diga. La explicación de cada resultado está en retos_explicados.md.


-- =====================================================================================
-- C01. Venta neta por mes (fecha del evento), con las notas crédito.
-- Cada nota resta en el mes en que se hizo, no en el mes de la factura original.
-- =====================================================================================
SELECT f.anio_mes,
       sum(v.venta_neta) FILTER (WHERE v.tipo_evento = 'FACTURA')                 AS venta_facturas,
       coalesce(sum(v.venta_neta) FILTER (WHERE v.tipo_evento = 'NOTA_CREDITO'), 0) AS notas_credito,
       sum(v.venta_neta)                                                          AS venta_neta,
       round(100 * (sum(v.venta_neta) / lag(sum(v.venta_neta)) OVER (ORDER BY f.anio_mes) - 1), 1) AS variacion_pct
FROM dwh.fact_venta v
JOIN dwh.dim_fecha f ON f.fecha_key = v.fecha_key
GROUP BY f.anio_mes
ORDER BY f.anio_mes;


-- =====================================================================================
-- C02. Top 10 clientes por venta neta, con su margen bruto.
-- Margen bruto = venta neta - costo de lo vendido. NO incluye arriendos, nómina,
-- transporte, comisiones ni impuestos: no es la utilidad.
-- =====================================================================================
WITH c AS (
    SELECT cliente_key, sum(venta_neta) AS venta_neta, sum(venta_neta - costo_venta) AS margen_bruto
    FROM dwh.fact_venta GROUP BY cliente_key
)
SELECT rank() OVER (ORDER BY c.venta_neta DESC)   AS puesto_venta,
       rank() OVER (ORDER BY c.margen_bruto DESC) AS puesto_margen,
       d.cliente_id, d.nombre, d.segmento, d.ciudad,
       c.venta_neta, c.margen_bruto,
       round(100 * c.margen_bruto / c.venta_neta, 1) AS margen_pct
FROM c JOIN dwh.dim_cliente d ON d.cliente_key = c.cliente_key
ORDER BY c.venta_neta DESC
LIMIT 10;


-- =====================================================================================
-- C03. Metas contra ventas por vendedor, sucursal y mes SIN duplicar la meta.
-- Primero se resume la venta al mismo nivel de la meta (vendedor + sucursal + mes)
-- y solo después se unen. Así cada meta aparece una sola vez.
-- =====================================================================================
WITH venta_mes AS (
    SELECT vendedor_key, sucursal_key, fecha_key / 100 AS periodo, sum(venta_neta) AS venta_neta
    FROM dwh.fact_venta GROUP BY 1, 2, 3
), meta_mes AS (
    SELECT vendedor_key, sucursal_key, mes_fecha_key / 100 AS periodo, monto_meta
    FROM dwh.fact_meta
), cruce AS (
    SELECT * FROM meta_mes m FULL JOIN venta_mes v USING (vendedor_key, sucursal_key, periodo)
)
-- Control: 360 filas (15 vendedores x 24 meses) y la meta total sin inflar.
SELECT count(*) AS filas, sum(monto_meta) AS meta_total, sum(venta_neta) AS venta_total,
       round(100 * sum(venta_neta) / sum(monto_meta), 1) AS cumplimiento_pct,
       count(*) FILTER (WHERE monto_meta IS NULL) AS ventas_sin_meta,
       count(*) FILTER (WHERE venta_neta IS NULL) AS metas_sin_venta
FROM cruce;

WITH venta_mes AS (
    SELECT vendedor_key, sucursal_key, fecha_key / 100 AS periodo, sum(venta_neta) AS venta_neta
    FROM dwh.fact_venta GROUP BY 1, 2, 3
), cruce AS (
    SELECT m.vendedor_key, m.sucursal_key, m.monto_meta, coalesce(v.venta_neta, 0) AS venta_neta
    FROM dwh.fact_meta m
    LEFT JOIN venta_mes v ON v.vendedor_key = m.vendedor_key AND v.sucursal_key = m.sucursal_key
                         AND v.periodo = m.mes_fecha_key / 100
)
SELECT d.vendedor_id, d.nombre AS vendedor, s.nombre AS sucursal,
       sum(c.monto_meta) AS meta, sum(c.venta_neta) AS venta_neta,
       round(100 * sum(c.venta_neta) / sum(c.monto_meta), 1) AS cumplimiento_pct,
       count(*) FILTER (WHERE c.venta_neta >= c.monto_meta) AS meses_que_cumplio
FROM cruce c
JOIN dwh.dim_vendedor d ON d.vendedor_key = c.vendedor_key
JOIN dwh.dim_sucursal s ON s.sucursal_key = c.sucursal_key
GROUP BY d.vendedor_id, d.nombre, s.nombre
ORDER BY cumplimiento_pct DESC;


-- =====================================================================================
-- C04. Existencias por producto y bodega al corte.
-- El saldo es la suma de TODOS los movimientos hasta el corte. No se suman fotos de
-- varias fechas (eso contaría las mismas unidades varias veces).
-- =====================================================================================
SELECT bodega, count(*) AS productos,
       sum(existencia_a_corte) AS unidades,
       count(*) FILTER (WHERE existencia_a_corte = 0) AS productos_en_cero,
       count(*) FILTER (WHERE existencia_a_corte < 0) AS productos_negativos
FROM dwh.vw_stock_corte
GROUP BY ROLLUP (bodega)
ORDER BY bodega NULLS LAST;

-- Los 10 productos con menos existencia en las bodegas de las sucursales.
SELECT bodega, producto_id, producto, categoria, existencia_a_corte
FROM dwh.vw_stock_corte
WHERE sucursal_id IS NOT NULL
ORDER BY existencia_a_corte, bodega, producto_id
LIMIT 10;


-- =====================================================================================
-- C05. Devoluciones por producto.
-- Denominador: unidades FACTURADAS (lo que salió en facturas, antes de devoluciones).
-- Si se usara la venta neta, el denominador ya tendría restadas las devoluciones.
-- =====================================================================================
WITH x AS (
    SELECT producto_key,
           sum(unidades) FILTER (WHERE tipo_evento = 'FACTURA')                        AS unidades_facturadas,
           -coalesce(sum(unidades) FILTER (WHERE tipo_evento = 'NOTA_CREDITO'), 0)      AS unidades_devueltas
    FROM dwh.fact_venta GROUP BY producto_key
)
SELECT 'TOTAL EMPRESA' AS producto, NULL::text AS categoria,
       sum(unidades_facturadas) AS unidades_facturadas, sum(unidades_devueltas) AS unidades_devueltas,
       round(100.0 * sum(unidades_devueltas) / sum(unidades_facturadas), 2) AS tasa_devolucion_pct
FROM x
UNION ALL
(SELECT p.nombre, p.categoria, x.unidades_facturadas, x.unidades_devueltas,
        round(100.0 * x.unidades_devueltas / x.unidades_facturadas, 2)
 FROM x JOIN dwh.dim_producto p ON p.producto_key = x.producto_key
 WHERE x.unidades_facturadas >= 50          -- para no sacar conclusiones con muy pocas ventas
 ORDER BY 5 DESC, 4 DESC
 LIMIT 10);

-- Por categoría.
SELECT p.categoria,
       sum(v.unidades) FILTER (WHERE v.tipo_evento = 'FACTURA')                   AS unidades_facturadas,
       -coalesce(sum(v.unidades) FILTER (WHERE v.tipo_evento = 'NOTA_CREDITO'), 0) AS unidades_devueltas,
       round(-100.0 * coalesce(sum(v.unidades) FILTER (WHERE v.tipo_evento = 'NOTA_CREDITO'), 0)
             / sum(v.unidades) FILTER (WHERE v.tipo_evento = 'FACTURA'), 2)       AS tasa_devolucion_pct
FROM dwh.fact_venta v JOIN dwh.dim_producto p ON p.producto_key = v.producto_key
GROUP BY p.categoria
ORDER BY tasa_devolucion_pct DESC;


-- =====================================================================================
-- C06. Facturas vencidas y saldo al corte (vista dwh.vw_cartera_corte del script 10).
-- Montos CON IVA, porque eso es lo que el cliente debe pagar.
-- =====================================================================================
SELECT count(*)                                AS facturas_al_corte,
       count(*) FILTER (WHERE saldo > 0)        AS facturas_con_saldo,
       count(*) FILTER (WHERE cartera_vencida > 0) AS facturas_vencidas,
       sum(total_factura)                      AS total_facturado,
       sum(notas_credito)                      AS notas_credito,
       sum(recaudado)                          AS recaudado,
       sum(saldo)                              AS saldo,
       sum(cartera_vencida)                    AS cartera_vencida,
       round(100 * sum(cartera_vencida) / sum(saldo), 1) AS vencida_pct_del_saldo
FROM dwh.vw_cartera_corte;

-- Por antigüedad (días vencida al corte).
SELECT CASE WHEN cartera_vencida = 0           THEN '0. Aún no vence'
            WHEN dias_desde_vencimiento <= 30  THEN '1. 1 a 30 días'
            WHEN dias_desde_vencimiento <= 90  THEN '2. 31 a 90 días'
            WHEN dias_desde_vencimiento <= 180 THEN '3. 91 a 180 días'
            ELSE '4. Más de 180 días' END      AS antiguedad,
       count(*) AS facturas, sum(saldo) AS saldo,
       round(100 * sum(saldo) / sum(sum(saldo)) OVER (), 1) AS pct_del_saldo
FROM dwh.vw_cartera_corte
WHERE saldo > 0
GROUP BY 1 ORDER BY 1;

-- Por tipo de cliente (persona paga de contado; empresa tiene 30 días).
SELECT c.segmento, c.plazo_credito_dias, count(*) AS facturas,
       sum(v.saldo) AS saldo, sum(v.cartera_vencida) AS cartera_vencida
FROM dwh.vw_cartera_corte v JOIN dwh.dim_cliente c ON c.cliente_id = v.cliente_id
GROUP BY c.segmento, c.plazo_credito_dias ORDER BY c.segmento;


-- =====================================================================================
-- C07. Vendedores que cumplen la meta (>= 100 %) pero con margen bruto bajo.
-- "Bajo" = 2 puntos o más por debajo del margen de toda la empresa ESE MISMO MES.
-- Se compara por mes porque la meta es mensual.
-- =====================================================================================
WITH venta_mes AS (
    SELECT vendedor_key, sucursal_key, fecha_key / 100 AS periodo,
           sum(venta_neta) AS venta_neta, sum(venta_neta - costo_venta) AS margen,
           sum(descuento) AS descuento, sum(valor_bruto) AS bruto
    FROM dwh.fact_venta GROUP BY 1, 2, 3
), empresa_mes AS (
    SELECT fecha_key / 100 AS periodo, sum(venta_neta - costo_venta) / sum(venta_neta) AS margen_empresa
    FROM dwh.fact_venta GROUP BY 1
)
SELECT d.vendedor_id, d.nombre AS vendedor, v.periodo,
       round(100 * v.venta_neta / m.monto_meta, 1)  AS cumplimiento_pct,
       round(100 * v.margen / v.venta_neta, 1)      AS margen_pct,
       round(100 * e.margen_empresa, 1)             AS margen_empresa_pct,
       round(100 * v.descuento / v.bruto, 1)        AS descuento_pct
FROM venta_mes v
JOIN dwh.fact_meta m   ON m.vendedor_key = v.vendedor_key AND m.sucursal_key = v.sucursal_key
                      AND m.mes_fecha_key / 100 = v.periodo
JOIN empresa_mes e     ON e.periodo = v.periodo
JOIN dwh.dim_vendedor d ON d.vendedor_key = v.vendedor_key
WHERE v.venta_neta >= m.monto_meta
  AND v.margen / v.venta_neta < e.margen_empresa - 0.02
ORDER BY d.vendedor_id, v.periodo;

-- Contexto: descuento promedio y margen de cada vendedor en todo el periodo.
SELECT d.vendedor_id, d.nombre AS vendedor,
       round(100 * sum(v.descuento) / sum(v.valor_bruto), 1)               AS descuento_pct,
       round(100 * sum(v.venta_neta - v.costo_venta) / sum(v.venta_neta), 1) AS margen_pct
FROM dwh.fact_venta v JOIN dwh.dim_vendedor d ON d.vendedor_key = v.vendedor_key
GROUP BY d.vendedor_id, d.nombre
ORDER BY descuento_pct DESC;


-- =====================================================================================
-- C08. Pedidos PENDIENTE_STOCK: ¿había existencia en la bodega local y en la central
-- el día del pedido?
-- Se usa la operación (oltp) porque los pedidos no son ventas y no están en el modelo.
-- OJO: las fechas no tienen hora. Si el mismo día hubo un movimiento en esa bodega y ese
-- producto, no sabemos si pasó antes o después del pedido. Esos casos se cuentan aparte.
-- =====================================================================================
WITH linea AS (
    SELECT p.pedido_id, p.fecha_pedido, p.sucursal_id, pd.producto_id, pd.cantidad,
           bl.bodega_id AS bodega_local
    FROM oltp.pedido p
    JOIN oltp.pedido_detalle pd ON pd.pedido_id = p.pedido_id
    JOIN oltp.bodega bl ON bl.sucursal_id = p.sucursal_id
    WHERE p.estado = 'PENDIENTE_STOCK'
), saldo AS (
    SELECT l.*,
           (SELECT coalesce(sum(m.cantidad_delta), 0) FROM oltp.movimiento_inventario m
             WHERE m.bodega_id = l.bodega_local AND m.producto_id = l.producto_id
               AND m.fecha_movimiento <= l.fecha_pedido)                         AS existencia_local,
           (SELECT coalesce(sum(m.cantidad_delta), 0) FROM oltp.movimiento_inventario m
             JOIN oltp.bodega b ON b.bodega_id = m.bodega_id AND b.tipo = 'CENTRAL'
             WHERE m.producto_id = l.producto_id AND m.fecha_movimiento <= l.fecha_pedido) AS existencia_central,
           EXISTS (SELECT 1 FROM oltp.movimiento_inventario m
                    WHERE m.bodega_id = l.bodega_local AND m.producto_id = l.producto_id
                      AND m.fecha_movimiento = l.fecha_pedido)                    AS movimiento_mismo_dia
    FROM linea l
)
SELECT s.nombre AS sucursal,
       count(DISTINCT x.pedido_id)                                             AS pedidos,
       count(*)                                                                AS lineas,
       count(*) FILTER (WHERE x.existencia_local < x.cantidad)                 AS lineas_sin_stock_local,
       count(*) FILTER (WHERE x.existencia_local < x.cantidad
                          AND x.existencia_central >= x.cantidad)              AS la_central_si_tenia,
       count(*) FILTER (WHERE x.existencia_local < x.cantidad
                          AND x.existencia_central < x.cantidad)               AS no_habia_en_ninguna,
       count(*) FILTER (WHERE x.existencia_local < x.cantidad
                          AND x.movimiento_mismo_dia)                          AS dudosas_por_mismo_dia
FROM saldo x JOIN oltp.sucursal s ON s.sucursal_id = x.sucursal_id
GROUP BY ROLLUP (s.nombre)
ORDER BY s.nombre NULLS LAST;


-- =====================================================================================
-- C09. Categorías con mayor descuento efectivo.
-- Descuento efectivo = pesos descontados / valor bruto (lo que se habría cobrado a precio
-- de la factura sin descuento). Incluye las notas crédito con su signo.
-- =====================================================================================
SELECT p.categoria,
       sum(v.valor_bruto)                                                   AS valor_bruto,
       sum(v.descuento)                                                     AS descuento,
       round(100 * sum(v.descuento) / sum(v.valor_bruto), 2)                AS descuento_efectivo_pct,
       round(100 * sum(v.venta_neta - v.costo_venta) / sum(v.venta_neta), 1) AS margen_pct
FROM dwh.fact_venta v JOIN dwh.dim_producto p ON p.producto_key = v.producto_key
GROUP BY p.categoria
ORDER BY descuento_efectivo_pct DESC;


-- =====================================================================================
-- C10. Flujo mensual de facturación y recaudo (CON IVA).
-- Facturado y recaudado son flujos de cada mes. Restarlos mes a mes NO dice qué facturas
-- están vencidas ni hace cuánto: un pago de octubre puede ser de una factura de enero.
-- La cartera se mide factura por factura (C06).
-- =====================================================================================
WITH fac AS (
    SELECT fecha_key / 100 AS periodo,
           sum(valor_facturado_con_impuesto) FILTER (WHERE tipo_evento = 'FACTURA')                 AS facturado,
           -coalesce(sum(valor_facturado_con_impuesto) FILTER (WHERE tipo_evento = 'NOTA_CREDITO'), 0) AS notas
    FROM dwh.fact_venta GROUP BY 1
), rec AS (
    SELECT fecha_key / 100 AS periodo, sum(monto_recaudado) AS recaudado
    FROM dwh.fact_recaudo GROUP BY 1
)
SELECT f.periodo, f.facturado, f.notas, coalesce(r.recaudado, 0) AS recaudado,
       round(100 * coalesce(r.recaudado, 0) / f.facturado, 1) AS recaudo_sobre_facturado_pct
FROM fac f LEFT JOIN rec r ON r.periodo = f.periodo
ORDER BY f.periodo;

-- Lo que sí cuadra y lo que no: el total acumulado coincide con el saldo de la cartera,
-- pero la resta de flujos no puede decir cuánto de eso está vencido.
SELECT (SELECT sum(valor_facturado_con_impuesto) FROM dwh.fact_venta)
     - (SELECT sum(monto_recaudado) FROM dwh.fact_recaudo)   AS facturado_menos_recaudado,
       (SELECT sum(saldo) FROM dwh.vw_cartera_corte)          AS saldo_cartera_por_factura,
       (SELECT sum(cartera_vencida) FROM dwh.vw_cartera_corte) AS vencida_solo_se_ve_por_factura;


-- =====================================================================================
-- C11. BONUS. Concentración de ventas por cliente (Pareto).
-- ¿Cuántos clientes hacen el 80 % de la venta neta?
-- =====================================================================================
WITH c AS (
    SELECT cliente_key, sum(venta_neta) AS venta_neta FROM dwh.fact_venta GROUP BY cliente_key
), acumulado AS (
    SELECT cliente_key,
           row_number() OVER (ORDER BY venta_neta DESC, cliente_key)          AS puesto,
           sum(venta_neta) OVER (ORDER BY venta_neta DESC, cliente_key)
             / sum(venta_neta) OVER ()                                        AS pct_acumulado,
           count(*) OVER ()                                                   AS clientes
    FROM c
)
SELECT max(clientes)                                                          AS clientes_con_compras,
       min(puesto) FILTER (WHERE pct_acumulado >= 0.8)                        AS clientes_para_el_80_pct,
       round(100.0 * min(puesto) FILTER (WHERE pct_acumulado >= 0.8) / max(clientes), 1) AS pct_de_clientes,
       round(100 * max(pct_acumulado) FILTER (WHERE puesto <= clientes / 5), 1)          AS venta_del_20_pct_mayor
FROM acumulado;


-- =====================================================================================
-- C12. BONUS. Una gráfica errada de "meta por categoría".
-- La meta es por vendedor, sucursal y mes: NO tiene categoría. Si se une la tabla de
-- metas con la de ventas por categoría (por ejemplo, en Power BI), cada meta se repite
-- una vez por cada categoría que vendió ese vendedor ese mes.
-- =====================================================================================
SELECT 'Así NO (meta repetida por categoría)' AS forma,
       count(*) AS filas, sum(m.meta_ventas) AS meta_total
FROM dwh.vw_ventas_mensuales v
JOIN dwh.vw_metas_mensuales m ON m.periodo_yyyymm = v.periodo_yyyymm
                             AND m.vendedor_id = v.vendedor_id AND m.sucursal_id = v.sucursal_id
UNION ALL
SELECT 'Así SÍ (meta en su propio nivel)', count(*), sum(meta_ventas)
FROM dwh.vw_metas_mensuales;

-- Cómo se vería la gráfica errada: cada categoría "tendría" casi la meta completa.
SELECT v.categoria, sum(m.meta_ventas) AS meta_que_mostraria_la_grafica, sum(v.venta_neta) AS venta_neta
FROM dwh.vw_ventas_mensuales v
JOIN dwh.vw_metas_mensuales m ON m.periodo_yyyymm = v.periodo_yyyymm
                             AND m.vendedor_id = v.vendedor_id AND m.sucursal_id = v.sucursal_id
GROUP BY v.categoria
ORDER BY v.categoria;
