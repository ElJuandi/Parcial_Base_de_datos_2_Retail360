-- RETAIL 360 | 06 | Aceptación cuantitativa + reconciliación.
-- Conteos esperados: fact_venta = factura_detalle + nota_credito_detalle (si no hay facturas anuladas)
SELECT 'venta_lineas' AS control,
 (SELECT count(*) FROM dwh.fact_venta) AS dwh,
 (SELECT count(*) FROM oltp.factura_detalle) + (SELECT count(*) FROM oltp.nota_credito_detalle) AS oltp;
SELECT 'inventario_movimientos' AS control,
 (SELECT count(*) FROM dwh.fact_movimiento_inventario) AS dwh,
 (SELECT count(*) FROM oltp.movimiento_inventario) AS oltp;
SELECT 'metas' AS control,
 (SELECT count(*) FROM dwh.fact_meta) AS dwh,
 (SELECT count(*) FROM oltp.meta_mensual) AS oltp;
SELECT 'recaudos' AS control,
 (SELECT count(*) FROM dwh.fact_recaudo) AS dwh,
 (SELECT count(*) FROM oltp.pago) AS oltp;
-- Reconciliación de ventas y NC al centavo, recalculada desde origen.
WITH ventas AS (
 SELECT SUM(
  fd.precio_unitario*fd.cantidad - ROUND(ROUND(fd.precio_unitario*fd.cantidad,2)*fd.descuento_pct,2)
 ) AS total FROM oltp.factura_detalle fd JOIN oltp.factura f USING(factura_id) WHERE f.estado='EMITIDA'
), notas AS (
 SELECT SUM(
  fd.precio_unitario*ncd.cantidad - ROUND(ROUND(fd.precio_unitario*ncd.cantidad,2)*fd.descuento_pct,2)
 ) AS total FROM oltp.nota_credito_detalle ncd
 JOIN oltp.factura_detalle fd USING(factura_detalle_id)
 JOIN oltp.nota_credito nc USING(nota_id)
 JOIN oltp.factura f ON f.factura_id=nc.factura_id WHERE f.estado='EMITIDA'
)
SELECT ROUND((SELECT total FROM ventas)-(SELECT COALESCE(total,0) FROM notas),2) AS venta_neta_oltp,
 (SELECT SUM(venta_neta) FROM dwh.fact_venta) AS venta_neta_dwh,
 ROUND((SELECT total FROM ventas)-(SELECT COALESCE(total,0) FROM notas)-
   (SELECT SUM(venta_neta) FROM dwh.fact_venta),2) AS diferencia;
-- Prueba de errores de cardinalidad: no debe haber claves huerfanas.
SELECT count(*) AS metas_duplicadas FROM (
 SELECT vendedor_key,mes_fecha_key,sucursal_key,COUNT(*) n
 FROM dwh.fact_meta GROUP BY 1,2,3 HAVING COUNT(*)>1
) x;
SELECT * FROM dwh.bitacora_carga ORDER BY corrida_id DESC LIMIT 5;
