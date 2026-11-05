-- Retail 360 | R5 | Valor oficial de cada indicador, calculado en SQL.
-- Estos son los números contra los que se van a comparar Power BI (R6) y la página web (R7).
-- Dos escenarios con los mismos filtros en las tres herramientas:
--   A = toda la empresa, todo el periodo (oct-2024 a sep-2026).
--   B = solo Sucursal Pereira, solo septiembre de 2026.
-- Existencias y cartera son fotos al corte (30/09/2026): en B solo cambia la sucursal/bodega.
-- Solo consulta, no cambia datos. Necesita R3 y los scripts 07 y 10.

WITH
p AS (SELECT 2 AS sucursal_b, 202609 AS mes_b, DATE '2026-09-30' AS corte),

venta AS (
    SELECT v.*, s.sucursal_id, v.fecha_key / 100 AS periodo
    FROM dwh.fact_venta v JOIN dwh.dim_sucursal s ON s.sucursal_key = v.sucursal_key
),
venta_ab AS (
    SELECT 'A' AS esc, * FROM venta
    UNION ALL
    SELECT 'B', venta.* FROM venta, p WHERE venta.sucursal_id = p.sucursal_b AND venta.periodo = p.mes_b
),
k_venta AS (
    SELECT esc,
           sum(venta_neta)                                                    AS ventas_netas,
           sum(unidades)                                                      AS unidades_netas,
           round(100 * sum(descuento) / sum(valor_bruto), 2)                  AS descuento_pct,
           round(-100.0 * coalesce(sum(unidades) FILTER (WHERE tipo_evento = 'NOTA_CREDITO'), 0)
                 / sum(unidades) FILTER (WHERE tipo_evento = 'FACTURA'), 2)   AS devolucion_pct,
           sum(venta_neta - costo_venta)                                      AS margen_bruto,
           round(100 * sum(venta_neta - costo_venta) / sum(venta_neta), 2)    AS margen_pct,
           sum(valor_facturado_con_impuesto)                                  AS facturado_con_iva
    FROM venta_ab GROUP BY esc
),

meta AS (
    SELECT m.*, s.sucursal_id, m.mes_fecha_key / 100 AS periodo
    FROM dwh.fact_meta m JOIN dwh.dim_sucursal s ON s.sucursal_key = m.sucursal_key
),
-- Venta resumida al nivel de la meta (vendedor + sucursal + mes) ANTES de cruzar.
venta_meta_nivel AS (
    SELECT vendedor_key, sucursal_key, periodo, sum(venta_neta) AS venta_neta FROM venta GROUP BY 1, 2, 3
),
meta_cruce AS (
    SELECT m.sucursal_id, m.periodo, m.monto_meta, coalesce(v.venta_neta, 0) AS venta_neta
    FROM meta m LEFT JOIN venta_meta_nivel v
      ON v.vendedor_key = m.vendedor_key AND v.sucursal_key = m.sucursal_key AND v.periodo = m.periodo
),
meta_ab AS (
    SELECT 'A' AS esc, * FROM meta_cruce
    UNION ALL
    SELECT 'B', meta_cruce.* FROM meta_cruce, p WHERE meta_cruce.sucursal_id = p.sucursal_b AND meta_cruce.periodo = p.mes_b
),
k_meta AS (
    SELECT esc, sum(monto_meta) AS meta,
           round(100 * sum(venta_neta) / sum(monto_meta), 2) AS cumplimiento_pct,
           round(100.0 * count(*) FILTER (WHERE venta_neta >= monto_meta) / count(*), 2) AS meses_cumplidos_pct
    FROM meta_ab GROUP BY esc
),

stock AS (
    SELECT 'A' AS esc, * FROM dwh.vw_stock_corte
    UNION ALL
    SELECT 'B', s.* FROM dwh.vw_stock_corte s, p WHERE s.sucursal_id = p.sucursal_b
),
k_stock AS (
    SELECT esc, sum(existencia_a_corte) AS existencias,
           count(*) FILTER (WHERE existencia_a_corte <= 0 AND sucursal_id IS NOT NULL) AS agotados_local
    FROM stock GROUP BY esc
),

recaudo AS (
    SELECT r.monto_recaudado, s.sucursal_id, r.fecha_key / 100 AS periodo
    FROM dwh.fact_recaudo r JOIN dwh.dim_sucursal s ON s.sucursal_key = r.sucursal_key
),
k_recaudo AS (
    SELECT 'A' AS esc, sum(monto_recaudado) AS recaudo FROM recaudo
    UNION ALL
    SELECT 'B', sum(monto_recaudado) FROM recaudo, p WHERE recaudo.sucursal_id = p.sucursal_b AND recaudo.periodo = p.mes_b
),

cartera AS (
    SELECT 'A' AS esc, * FROM dwh.vw_cartera_corte
    UNION ALL
    SELECT 'B', c.* FROM dwh.vw_cartera_corte c, p WHERE c.sucursal_id = p.sucursal_b
),
k_cartera AS (
    SELECT esc, sum(saldo) AS saldo_cartera,
           round(100 * sum(cartera_vencida) / sum(saldo), 2) AS cartera_vencida_pct
    FROM cartera GROUP BY esc
),

todo AS (
    SELECT * FROM k_venta JOIN k_meta USING (esc) JOIN k_stock USING (esc)
                          JOIN k_recaudo USING (esc) JOIN k_cartera USING (esc)
)
SELECT k.n AS num, k.kpi,
       max(k.valor) FILTER (WHERE t.esc = 'A') AS escenario_a_todo,
       max(k.valor) FILTER (WHERE t.esc = 'B') AS escenario_b_pereira_sep2026
FROM todo t
CROSS JOIN LATERAL (VALUES
    ( 1, 'K01 Ventas netas (COP sin IVA)',            t.ventas_netas),
    ( 2, 'K02 Unidades netas',                        t.unidades_netas),
    ( 3, 'K03 Descuento efectivo %',                  t.descuento_pct),
    ( 4, 'K04 Tasa de devolución % (unidades)',       t.devolucion_pct),
    ( 5, 'K05 Margen bruto (COP)',                    t.margen_bruto),
    ( 6, 'K06 Margen bruto %',                        t.margen_pct),
    ( 7, 'K07 Meta de ventas (COP)',                  t.meta),
    ( 8, 'K08 Cumplimiento de meta %',                t.cumplimiento_pct),
    ( 9, 'K09 Meses-vendedor con meta cumplida %',    t.meses_cumplidos_pct),
    (10, 'K10 Existencias al corte (unidades)',       t.existencias),
    (11, 'K11 Productos agotados en sucursales',      t.agotados_local),
    (12, 'K12 Recaudo (COP con IVA)',                 t.recaudo),
    (13, 'K13 Saldo de cartera al corte (COP con IVA)', t.saldo_cartera),
    (14, 'K14 Cartera vencida %',                     t.cartera_vencida_pct),
    (15, 'K15 Facturación con IVA (COP)',             t.facturado_con_iva)
) AS k(n, kpi, valor)
GROUP BY k.n, k.kpi
ORDER BY k.n;
