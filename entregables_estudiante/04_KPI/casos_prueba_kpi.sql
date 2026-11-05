-- Retail 360 | R5 | Casos de prueba de los indicadores con datos pequeños.
-- Los resultados esperados los calculamos a mano (ver casos_prueba_kpi.md) ANTES de armar
-- los tableros. Aquí se comprueba que las fórmulas del catálogo dan exactamente eso, y que
-- las formas equivocadas dan otro número (para mostrar por qué no se usan).
-- Usa tablas temporales: no toca la base. Si un resultado no coincide, se detiene con error.

CREATE TEMP TABLE t_venta (
    linea text, tipo_evento text, mes int, vendedor text, categoria text,
    unidades int, valor_bruto numeric, descuento numeric, venta_neta numeric, costo_venta numeric,
    impuesto numeric
);
INSERT INTO t_venta VALUES
 ('F1', 'FACTURA',      1, 'Ana',  'Portátiles',  2, 1000, 100,  900,  600, 171),
 ('F2', 'FACTURA',      1, 'Ana',  'Mouse',       1,  500,   0,  500,  400,  95),
 ('F3', 'FACTURA',      1, 'Beto', 'Portátiles',  4, 2000, 400, 1600, 1200, 304),
 ('N1', 'NOTA_CREDITO', 2, 'Ana',  'Portátiles', -1, -500, -50, -450, -300, -85.5);  -- devuelven 1 de F1, en febrero

CREATE TEMP TABLE t_meta (vendedor text, mes int, monto_meta numeric);
INSERT INTO t_meta VALUES ('Ana', 1, 2000), ('Beto', 1, 1500), ('Ana', 2, 1000), ('Beto', 2, 1000);

CREATE TEMP TABLE t_mov (bodega text, producto text, dia int, cantidad_delta int);
INSERT INTO t_mov VALUES
 ('Local', 'P', 1, 10), ('Local', 'P', 15, -3), ('Local', 'P', 40, -7),   -- P termina en 0
 ('Local', 'Q', 1, 5);                                                    -- Q no se mueve

CREATE TEMP TABLE t_factura (factura text, total numeric, notas numeric, vence_dia int);
INSERT INTO t_factura VALUES ('FA', 1000, 100, 10), ('FB', 2000, 0, 70);
CREATE TEMP TABLE t_pago (factura text, dia int, monto numeric);
INSERT INTO t_pago VALUES ('FA', 20, 400), ('FB', 45, 500);

DO $$
DECLARE
    corte int := 59;   -- día de corte del ejemplo (fin de febrero)
    r record;
    malo numeric;
    fallas text := '';
BEGIN
    -- ---------- Ventas y margen ----------
    SELECT sum(venta_neta) AS ventas, sum(unidades) AS unidades,
           round(100 * sum(descuento) / sum(valor_bruto), 2) AS descuento_pct,
           round(-100.0 * sum(unidades) FILTER (WHERE tipo_evento = 'NOTA_CREDITO')
                 / sum(unidades) FILTER (WHERE tipo_evento = 'FACTURA'), 2) AS devolucion_pct,
           sum(venta_neta - costo_venta) AS margen,
           round(100 * sum(venta_neta - costo_venta) / sum(venta_neta), 2) AS margen_pct,
           sum(venta_neta) FILTER (WHERE mes = 1) AS ventas_enero,
           sum(venta_neta) FILTER (WHERE mes = 2) AS ventas_febrero,
           sum(venta_neta + impuesto) AS facturado_con_iva
      INTO r FROM t_venta;

    IF r.ventas         <> 2550   THEN fallas := fallas || ' K01'; END IF;
    IF r.unidades       <> 6      THEN fallas := fallas || ' K02'; END IF;
    IF r.descuento_pct  <> 15.00  THEN fallas := fallas || ' K03'; END IF;
    IF r.devolucion_pct <> 14.29  THEN fallas := fallas || ' K04'; END IF;
    IF r.margen         <> 650    THEN fallas := fallas || ' K05'; END IF;
    IF r.margen_pct     <> 25.49  THEN fallas := fallas || ' K06'; END IF;
    IF r.ventas_enero <> 3000 OR r.ventas_febrero <> -450 THEN fallas := fallas || ' K01-mes'; END IF;
    IF r.facturado_con_iva <> 3034.5 THEN fallas := fallas || ' K15'; END IF;

    -- Trampa: promediar el margen % de cada línea en vez de dividir los totales.
    SELECT round(avg(100 * (venta_neta - costo_venta) / venta_neta), 2) INTO malo FROM t_venta;
    RAISE NOTICE 'Trampa margen: promedio de porcentajes = % %% (correcto: 25.49 %%)', malo;
    IF malo = 25.49 THEN fallas := fallas || ' trampa-margen'; END IF;

    -- Trampa: tasa de devolución con las unidades netas como denominador.
    SELECT round(100.0 * 1 / sum(unidades), 2) INTO malo FROM t_venta;
    RAISE NOTICE 'Trampa devolución: sobre unidades netas = % %% (correcto: 14.29 %%)', malo;

    -- ---------- Metas ----------
    -- Correcto: resumir la venta al nivel de la meta y luego cruzar.
    WITH v AS (SELECT vendedor, mes, sum(venta_neta) AS venta FROM t_venta GROUP BY 1, 2),
         c AS (SELECT m.monto_meta, coalesce(v.venta, 0) AS venta
               FROM t_meta m LEFT JOIN v USING (vendedor, mes))
    SELECT sum(monto_meta) AS meta, round(100 * sum(venta) / sum(monto_meta), 2) AS cumplimiento,
           round(100.0 * count(*) FILTER (WHERE venta >= monto_meta) / count(*), 2) AS meses_cumplidos
      INTO r FROM c;
    IF r.meta            <> 5500  THEN fallas := fallas || ' K07'; END IF;
    IF r.cumplimiento    <> 46.36 THEN fallas := fallas || ' K08'; END IF;
    IF r.meses_cumplidos <> 25.00 THEN fallas := fallas || ' K09'; END IF;

    -- Trampa: pegar la meta a cada línea de venta.
    SELECT sum(m.monto_meta) INTO malo
    FROM t_meta m JOIN t_venta v ON v.vendedor = m.vendedor AND v.mes = m.mes;
    RAISE NOTICE 'Trampa meta: pegada a cada línea = % (correcto: 5500)', malo;
    IF malo = 5500 THEN fallas := fallas || ' trampa-meta'; END IF;

    -- ---------- Inventario ----------
    SELECT sum(cantidad_delta) AS existencias INTO r FROM t_mov WHERE dia <= corte;
    IF r.existencias <> 5 THEN fallas := fallas || ' K10'; END IF;
    SELECT count(*) INTO malo FROM (SELECT producto FROM t_mov WHERE dia <= corte
                                    GROUP BY producto HAVING sum(cantidad_delta) <= 0) x;
    IF malo <> 1 THEN fallas := fallas || ' K11'; END IF;

    -- Trampa: sumar la foto de fin de enero (día 31) con la de fin de febrero (día 59).
    SELECT (SELECT sum(cantidad_delta) FROM t_mov WHERE dia <= 31)
         + (SELECT sum(cantidad_delta) FROM t_mov WHERE dia <= 59) INTO malo;
    RAISE NOTICE 'Trampa inventario: sumar fotos de dos meses = % unidades (correcto: 5)', malo;

    -- ---------- Recaudo y cartera ----------
    SELECT sum(monto) INTO malo FROM t_pago WHERE dia <= corte;
    IF malo <> 900 THEN fallas := fallas || ' K12'; END IF;

    WITH c AS (
        SELECT f.factura, f.total - f.notas - coalesce(sum(p.monto), 0) AS saldo, f.vence_dia
        FROM t_factura f LEFT JOIN t_pago p ON p.factura = f.factura AND p.dia <= corte
        GROUP BY f.factura, f.total, f.notas, f.vence_dia
    )
    SELECT sum(saldo) AS saldo,
           round(100 * sum(saldo) FILTER (WHERE vence_dia < corte) / sum(saldo), 2) AS vencida_pct
      INTO r FROM c;
    IF r.saldo       <> 2000  THEN fallas := fallas || ' K13'; END IF;
    IF r.vencida_pct <> 25.00 THEN fallas := fallas || ' K14'; END IF;

    IF fallas <> '' THEN
        RAISE EXCEPTION 'CASOS DE PRUEBA CON FALLAS:%', fallas;
    END IF;
    RAISE NOTICE 'CASOS DE PRUEBA OK: los 15 indicadores dan lo calculado a mano';
END $$;
