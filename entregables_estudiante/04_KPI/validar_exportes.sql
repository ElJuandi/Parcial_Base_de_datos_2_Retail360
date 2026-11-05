-- Retail 360 | R4 | Revisa que las 4 vistas que se exportan a CSV cuadren con el modelo.
-- Si una vista pierde o repite filas, los totales no coinciden y se nota aquí.
-- Las filas de cada vista deben ser las mismas que trae cada CSV (sin contar el encabezado).

SELECT 'ventas_mensuales.csv' AS archivo,
       (SELECT count(*) FROM dwh.vw_ventas_mensuales)         AS filas,
       'venta neta'                                           AS que_se_compara,
       (SELECT sum(venta_neta) FROM dwh.vw_ventas_mensuales)  AS total_en_vista,
       (SELECT sum(venta_neta) FROM dwh.fact_venta)           AS total_en_modelo
UNION ALL
SELECT 'metas_mensuales.csv',
       (SELECT count(*) FROM dwh.vw_metas_mensuales), 'meta',
       (SELECT sum(meta_ventas) FROM dwh.vw_metas_mensuales),
       (SELECT sum(monto_meta) FROM dwh.fact_meta)
UNION ALL
SELECT 'recaudos_mensuales.csv',
       (SELECT count(*) FROM dwh.vw_recaudos_mensuales), 'recaudo',
       (SELECT sum(monto_recaudado) FROM dwh.vw_recaudos_mensuales),
       (SELECT sum(monto_recaudado) FROM dwh.fact_recaudo)
UNION ALL
SELECT 'stock_corte.csv',
       (SELECT count(*) FROM dwh.vw_stock_corte), 'unidades al corte',
       (SELECT sum(existencia_a_corte) FROM dwh.vw_stock_corte),
       (SELECT sum(m.cantidad_delta) FROM dwh.fact_movimiento_inventario m
          JOIN dwh.dim_fecha f ON f.fecha_key = m.fecha_key WHERE f.fecha <= DATE '2026-09-30');

-- Otros totales de ventas_mensuales.csv, para comparar luego con Power BI y la página web.
SELECT sum(unidades_net) AS unidades, sum(costo_venta) AS costo_venta, sum(margen_bruto) AS margen_bruto,
       sum(descuentos) AS descuentos, sum(neto_con_impuestos) AS neto_con_impuestos,
       min(periodo_yyyymm) AS desde, max(periodo_yyyymm) AS hasta
FROM dwh.vw_ventas_mensuales;
