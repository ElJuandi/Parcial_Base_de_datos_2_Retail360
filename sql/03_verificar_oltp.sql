-- RETAIL 360 | 03 | Validacion de origen y conteos.
SELECT 'sucursales' AS entidad,count(*) AS registros FROM oltp.sucursal
UNION ALL SELECT 'clientes',count(*) FROM oltp.cliente
UNION ALL SELECT 'productos',count(*) FROM oltp.producto
UNION ALL SELECT 'pedidos',count(*) FROM oltp.pedido
UNION ALL SELECT 'facturas',count(*) FROM oltp.factura
UNION ALL SELECT 'lineas_factura',count(*) FROM oltp.factura_detalle
UNION ALL SELECT 'movimientos',count(*) FROM oltp.movimiento_inventario
UNION ALL SELECT 'pagos',count(*) FROM oltp.pago;
-- Deben devolver 0 (sin excepciones):
SELECT count(*) AS facturas_sin_pedido_facturado FROM oltp.factura f
JOIN oltp.pedido p USING(pedido_id) WHERE p.estado <> 'FACTURADO';
SELECT count(*) AS detalle_factura_inconsistente FROM oltp.factura_detalle fd
JOIN oltp.factura f USING(factura_id)
JOIN oltp.pedido_detalle pd ON pd.pedido_detalle_id=fd.pedido_detalle_id
WHERE pd.pedido_id<>f.pedido_id OR pd.producto_id<>fd.producto_id OR pd.cantidad<>fd.cantidad;
SELECT count(*) AS notas_con_cantidad_excedida FROM (
 SELECT nd.factura_detalle_id, sum(nd.cantidad) AS devuelta, max(fd.cantidad) AS vendida
 FROM oltp.nota_credito_detalle nd JOIN oltp.factura_detalle fd USING(factura_detalle_id)
 GROUP BY 1 HAVING sum(nd.cantidad)>max(fd.cantidad)) x;
-- Las existencias finales por bodega/producto no deben ser negativas:
SELECT count(*) AS saldos_finales_negativos FROM (
 SELECT bodega_id,producto_id,sum(cantidad_delta) AS saldo
 FROM oltp.movimiento_inventario GROUP BY 1,2 HAVING sum(cantidad_delta)<0
) x;
-- Investigar pedido pendiente por stock frente al saldo en su fecha; puede requerir unir con ventana acumulada.
