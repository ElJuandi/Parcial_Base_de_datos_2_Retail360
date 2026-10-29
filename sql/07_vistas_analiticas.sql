-- RETAIL 360 | 07 | Vistas de exportacion independientes por GRANULARIDAD.
-- No unir ventas y metas directamente por fila: se multiplicarian los importes.
CREATE OR REPLACE VIEW dwh.vw_ventas_mensuales AS
SELECT f.fecha_key / 100 AS periodo_yyyymm, s.sucursal_id, s.nombre AS sucursal,
 v.vendedor_id, v.nombre AS vendedor, p.categoria,
 SUM(f.unidades) AS unidades_net,
 SUM(f.venta_neta) AS venta_neta,
 SUM(f.costo_venta) AS costo_venta,
 SUM(f.venta_neta-f.costo_venta) AS margen_bruto,
 SUM(f.descuento) AS descuentos,
 SUM(f.valor_facturado_con_impuesto) AS neto_con_impuestos
FROM dwh.fact_venta f JOIN dwh.dim_sucursal s USING(sucursal_key)
JOIN dwh.dim_vendedor v USING(vendedor_key)
JOIN dwh.dim_producto p USING(producto_key)
GROUP BY 1,2,3,4,5,6;
CREATE OR REPLACE VIEW dwh.vw_metas_mensuales AS
SELECT m.mes_fecha_key/100 AS periodo_yyyymm,s.sucursal_id,s.nombre AS sucursal,
 v.vendedor_id,v.nombre AS vendedor,sum(m.monto_meta) AS meta_ventas
FROM dwh.fact_meta m JOIN dwh.dim_sucursal s USING(sucursal_key)
JOIN dwh.dim_vendedor v USING(vendedor_key)
GROUP BY 1,2,3,4,5;
CREATE OR REPLACE VIEW dwh.vw_recaudos_mensuales AS
SELECT r.fecha_key/100 AS periodo_yyyymm,s.sucursal_id,s.nombre AS sucursal,
 r.cliente_key,sum(r.monto_recaudado) AS monto_recaudado
FROM dwh.fact_recaudo r JOIN dwh.dim_sucursal s USING(sucursal_key)
GROUP BY 1,2,3,4;
CREATE OR REPLACE VIEW dwh.vw_stock_corte AS
SELECT b.bodega_id,b.nombre AS bodega,b.sucursal_id,p.producto_id,p.nombre AS producto,p.categoria,
 SUM(m.cantidad_delta) AS existencia_a_corte
FROM dwh.fact_movimiento_inventario m
JOIN dwh.dim_bodega b USING(bodega_key)
JOIN dwh.dim_producto p USING(producto_key)
JOIN dwh.dim_fecha f ON f.fecha_key=m.fecha_key
WHERE f.fecha <= date '2026-09-30'
GROUP BY 1,2,3,4,5,6;
-- La vista de existencias es foto al corte fijo, NO serie temporal.
