-- RETAIL 360 | 10 | Cartera al corte: no confundir flujo mensual de pagos con saldo de facturas.
-- PRERREQUISITOS: 01-05. Corte: 2026-09-30; ajuste explícito en el SQL si se requiere otra fecha.
-- Validación: cada factura aparece una sola vez; total_factura - notas - pagos = saldo.
-- Separación previa de montos por factura evita la multiplicación por JOIN de líneas y pagos.
CREATE OR REPLACE VIEW dwh.vw_cartera_corte AS
WITH corte AS (SELECT DATE '2026-09-30' AS fecha),
     base AS (
       SELECT f.factura_id, f.fecha_factura, f.fecha_vencimiento,
              p.cliente_id, p.sucursal_id, p.vendedor_id
       FROM oltp.factura f
       JOIN oltp.pedido p ON p.pedido_id=f.pedido_id
       CROSS JOIN corte
       WHERE f.estado='EMITIDA' AND f.fecha_factura<=corte.fecha
     ),
     importe_factura AS (
       SELECT fd.factura_id,
          SUM(
            (ROUND(fd.precio_unitario*fd.cantidad,2)
             -ROUND(ROUND(fd.precio_unitario*fd.cantidad,2)*fd.descuento_pct,2))
            +ROUND((ROUND(fd.precio_unitario*fd.cantidad,2)
             -ROUND(ROUND(fd.precio_unitario*fd.cantidad,2)*fd.descuento_pct,2))*fd.impuesto_pct,2)
          ) AS total_factura
       FROM oltp.factura_detalle fd GROUP BY fd.factura_id
     ),
     notas AS (
       SELECT n.factura_id,
         SUM(
           (ROUND(fd.precio_unitario*nd.cantidad,2)
            -ROUND(ROUND(fd.precio_unitario*nd.cantidad,2)*fd.descuento_pct,2))
            +ROUND((ROUND(fd.precio_unitario*nd.cantidad,2)
              -ROUND(ROUND(fd.precio_unitario*nd.cantidad,2)*fd.descuento_pct,2))*fd.impuesto_pct,2)
         ) AS total_nc
       FROM oltp.nota_credito n
       JOIN oltp.nota_credito_detalle nd ON nd.nota_id=n.nota_id
       JOIN oltp.factura_detalle fd ON fd.factura_detalle_id=nd.factura_detalle_id
       CROSS JOIN corte
       WHERE n.fecha_nota<=corte.fecha
       GROUP BY n.factura_id
     ),
     pagos AS (
       SELECT pg.factura_id, SUM(pg.monto) total_pago
       FROM oltp.pago pg CROSS JOIN corte
       WHERE pg.fecha_pago<=corte.fecha GROUP BY pg.factura_id
     )
SELECT b.factura_id,b.cliente_id,b.sucursal_id,b.vendedor_id,
       b.fecha_factura,b.fecha_vencimiento,c.fecha AS fecha_corte,
       i.total_factura,COALESCE(n.total_nc,0) AS notas_credito,
       COALESCE(p.total_pago,0) AS recaudado,
       i.total_factura-COALESCE(n.total_nc,0)-COALESCE(p.total_pago,0) AS saldo,
       CASE WHEN b.fecha_vencimiento<c.fecha
         THEN GREATEST(i.total_factura-COALESCE(n.total_nc,0)-COALESCE(p.total_pago,0),0)
         ELSE 0 END AS cartera_vencida,
       GREATEST(c.fecha-b.fecha_vencimiento,0) AS dias_desde_vencimiento
FROM base b
JOIN importe_factura i ON i.factura_id=b.factura_id
LEFT JOIN notas n ON n.factura_id=b.factura_id
LEFT JOIN pagos p ON p.factura_id=b.factura_id
CROSS JOIN corte c;
-- Verificaciones exploratorias:
SELECT count(*) AS facturas_corte, SUM(saldo) AS saldo_total,
       SUM(cartera_vencida) AS vencida_total,
       MIN(saldo) AS saldo_minimo
FROM dwh.vw_cartera_corte;
SELECT sucursal_id, SUM(saldo) saldo, SUM(cartera_vencida) vencida
FROM dwh.vw_cartera_corte GROUP BY sucursal_id ORDER BY sucursal_id;
