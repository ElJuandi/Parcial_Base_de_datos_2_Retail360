-- Retail 360 | R2 | Por qué la meta no se puede pegar a cada venta
-- La meta es UNA por vendedor, sucursal y mes. Una venta tiene MUCHAS líneas.
-- Si se unen directo, la meta se repite una vez por cada línea vendida y se infla.

-- 1. La meta real (360 filas, una por vendedor, sucursal y mes).
SELECT count(*) AS filas_meta, sum(monto_meta) AS meta_real
FROM oltp.meta_mensual;

-- 2. EL ERROR: unir la meta con cada línea de factura del mismo vendedor, sucursal y mes.
SELECT count(*) AS filas_despues_del_join, sum(m.monto_meta) AS meta_inflada
FROM oltp.meta_mensual m
JOIN oltp.pedido p  ON p.vendedor_id = m.vendedor_id AND p.sucursal_id = m.sucursal_id
JOIN oltp.factura f ON f.pedido_id = p.pedido_id
                   AND date_trunc('month', f.fecha_factura)::date = m.mes
JOIN oltp.factura_detalle fd ON fd.factura_id = f.factura_id;

-- Un ejemplo: la primera meta y cuántas veces se repite.
SELECT m.meta_id, m.vendedor_id, m.mes, m.monto_meta,
       count(fd.factura_detalle_id) AS veces_que_se_repite,
       m.monto_meta * count(fd.factura_detalle_id) AS meta_que_se_sumaria
FROM oltp.meta_mensual m
JOIN oltp.pedido p  ON p.vendedor_id = m.vendedor_id AND p.sucursal_id = m.sucursal_id
JOIN oltp.factura f ON f.pedido_id = p.pedido_id
                   AND date_trunc('month', f.fecha_factura)::date = m.mes
JOIN oltp.factura_detalle fd ON fd.factura_id = f.factura_id
WHERE m.meta_id = 1
GROUP BY m.meta_id, m.vendedor_id, m.mes, m.monto_meta;

-- 3. LA FORMA CORRECTA: primero sumar las ventas por vendedor, sucursal y mes,
--    y después unir con la meta (una fila contra una fila).
--    Venta = línea con descuento y sin impuesto. Aquí todavía sin notas crédito.
WITH ventas_mes AS (
  SELECT p.vendedor_id, p.sucursal_id, date_trunc('month', f.fecha_factura)::date AS mes,
         sum(round(fd.precio_unitario * fd.cantidad, 2)
           - round(round(fd.precio_unitario * fd.cantidad, 2) * fd.descuento_pct, 2)) AS venta
  FROM oltp.factura_detalle fd
  JOIN oltp.factura f USING (factura_id)
  JOIN oltp.pedido p  USING (pedido_id)
  GROUP BY 1, 2, 3
)
SELECT count(*) AS filas, sum(m.monto_meta) AS meta, sum(v.venta) AS venta,
       round(100 * sum(v.venta) / sum(m.monto_meta), 1) AS cumplimiento_pct
FROM oltp.meta_mensual m
LEFT JOIN ventas_mes v USING (vendedor_id, sucursal_id, mes);
