-- RETAIL 360 | 05 | ETL/ELT orientativo en PL/pgSQL, idempotente para cambios tipo 1.
-- Direccion OLTP -> DWH. Un solo CALL dentro de transaccion implicita.
-- En escenarios reales se requieren control de concurrencia, permisos y orquestacion.
-- Las notas crédito se representan como eventos negativos: NO borrar venta original.
-- Si el objetivo pedagógico es que el estudiante implemente su solución, este archivo
-- funciona como referencia de AUTOVALIDACION y no debe ser entregado antes de intentarlo.
CREATE OR REPLACE PROCEDURE dwh.cargar_retail360()
LANGUAGE plpgsql
AS $$
DECLARE v_corrida bigint; v_c1 bigint; v_c2 bigint; v_c3 bigint; v_c4 bigint;
BEGIN
 INSERT INTO dwh.bitacora_carga(estado,mensaje) VALUES ('EN_CURSO','Inicio de carga') RETURNING corrida_id INTO v_corrida;
 INSERT INTO dwh.dim_fecha(fecha_key,fecha,anio,mes_num,mes_inicio,trimestre,anio_mes)
 SELECT to_char(x.d,'YYYYMMDD')::integer, x.d,extract(year from x.d)::integer,
 extract(month from x.d)::integer,date_trunc('month',x.d)::date,
 extract(quarter from x.d)::integer,to_char(x.d,'YYYY-MM')
 FROM generate_series(date '2024-01-01',date '2027-12-31',interval '1 day') AS x(d)
 ON CONFLICT(fecha_key) DO NOTHING;
 INSERT INTO dwh.dim_sucursal(sucursal_id,nombre,ciudad)
 SELECT sucursal_id,nombre,ciudad FROM oltp.sucursal
 ON CONFLICT (sucursal_id) DO UPDATE SET nombre=EXCLUDED.nombre,ciudad=EXCLUDED.ciudad;
 INSERT INTO dwh.dim_bodega(bodega_id,nombre,tipo,sucursal_id)
 SELECT bodega_id,nombre,tipo,sucursal_id FROM oltp.bodega
 ON CONFLICT (bodega_id) DO UPDATE SET nombre=EXCLUDED.nombre,tipo=EXCLUDED.tipo,sucursal_id=EXCLUDED.sucursal_id;
 INSERT INTO dwh.dim_cliente(cliente_id,nombre,segmento,ciudad)
 SELECT cliente_id,nombre,segmento,ciudad FROM oltp.cliente
 ON CONFLICT(cliente_id) DO UPDATE SET nombre=EXCLUDED.nombre,segmento=EXCLUDED.segmento,ciudad=EXCLUDED.ciudad;
 INSERT INTO dwh.dim_vendedor(vendedor_id,nombre,sucursal_actual_id)
 SELECT vendedor_id,nombre,sucursal_id FROM oltp.vendedor
 ON CONFLICT(vendedor_id) DO UPDATE SET nombre=EXCLUDED.nombre,sucursal_actual_id=EXCLUDED.sucursal_actual_id;
 INSERT INTO dwh.dim_producto(producto_id,nombre,categoria_id,categoria)
 SELECT p.producto_id,p.nombre,p.categoria_id,c.nombre FROM oltp.producto p JOIN oltp.categoria c USING(categoria_id)
 ON CONFLICT(producto_id) DO UPDATE SET nombre=EXCLUDED.nombre,categoria_id=EXCLUDED.categoria_id,categoria=EXCLUDED.categoria;
 -- Hecho de facturacion, granularidad: una línea ORIGINAL de factura.
 INSERT INTO dwh.fact_venta(tipo_evento,linea_origen_id,factura_id,fecha_key,sucursal_key,cliente_key,vendedor_key,producto_key,
 unidades,valor_bruto,descuento,venta_neta,costo_venta,impuesto,valor_facturado_con_impuesto)
 SELECT 'FACTURA',fd.factura_detalle_id,f.factura_id,to_char(f.fecha_factura,'YYYYMMDD')::integer,
 ds.sucursal_key,dc.cliente_key,dv.vendedor_key,dp.producto_key, fd.cantidad,
 a.bruto,a.descuento,a.neto,round(fd.costo_unitario*fd.cantidad,2),a.impuesto,a.neto+a.impuesto
 FROM oltp.factura_detalle fd
 JOIN oltp.factura f USING(factura_id) JOIN oltp.pedido p USING(pedido_id)
 JOIN dwh.dim_sucursal ds ON ds.sucursal_id=p.sucursal_id
 JOIN dwh.dim_cliente dc ON dc.cliente_id=p.cliente_id
 JOIN dwh.dim_vendedor dv ON dv.vendedor_id=p.vendedor_id
 JOIN dwh.dim_producto dp ON dp.producto_id=fd.producto_id
 CROSS JOIN LATERAL (
   SELECT round(fd.precio_unitario*fd.cantidad,2) AS bruto,
   round(round(fd.precio_unitario*fd.cantidad,2)*fd.descuento_pct,2) AS descuento
 ) b
 CROSS JOIN LATERAL (
  SELECT b.bruto,b.descuento,b.bruto-b.descuento AS neto,
   round((b.bruto-b.descuento)*fd.impuesto_pct,2) AS impuesto
 ) a
 WHERE f.estado='EMITIDA'
 ON CONFLICT (tipo_evento,linea_origen_id) DO UPDATE SET
 fecha_key=EXCLUDED.fecha_key,sucursal_key=EXCLUDED.sucursal_key,
 cliente_key=EXCLUDED.cliente_key,vendedor_key=EXCLUDED.vendedor_key,producto_key=EXCLUDED.producto_key,
 unidades=EXCLUDED.unidades,valor_bruto=EXCLUDED.valor_bruto,descuento=EXCLUDED.descuento,
 venta_neta=EXCLUDED.venta_neta,costo_venta=EXCLUDED.costo_venta,impuesto=EXCLUDED.impuesto,
 valor_facturado_con_impuesto=EXCLUDED.valor_facturado_con_impuesto;
 -- Notas crédito: renglón de devolución, fecha de la nota y valores NEGATIVOS.
 INSERT INTO dwh.fact_venta(tipo_evento,linea_origen_id,factura_id,fecha_key,sucursal_key,cliente_key,vendedor_key,producto_key,
 unidades,valor_bruto,descuento,venta_neta,costo_venta,impuesto,valor_facturado_con_impuesto)
 SELECT 'NOTA_CREDITO',ncd.nota_detalle_id,f.factura_id,to_char(nc.fecha_nota,'YYYYMMDD')::integer,
 ds.sucursal_key,dc.cliente_key,dv.vendedor_key,dp.producto_key,-ncd.cantidad,
 -a.bruto,-a.descuento,-a.neto,-round(fd.costo_unitario*ncd.cantidad,2),-a.impuesto,-(a.neto+a.impuesto)
 FROM oltp.nota_credito_detalle ncd
 JOIN oltp.nota_credito nc USING(nota_id)
 JOIN oltp.factura_detalle fd USING(factura_detalle_id)
 JOIN oltp.factura f ON f.factura_id=nc.factura_id
 JOIN oltp.pedido p ON p.pedido_id=f.pedido_id
 JOIN dwh.dim_sucursal ds ON ds.sucursal_id=p.sucursal_id
 JOIN dwh.dim_cliente dc ON dc.cliente_id=p.cliente_id
 JOIN dwh.dim_vendedor dv ON dv.vendedor_id=p.vendedor_id
 JOIN dwh.dim_producto dp ON dp.producto_id=fd.producto_id
 CROSS JOIN LATERAL (
 SELECT round(fd.precio_unitario*ncd.cantidad,2) AS bruto,
 round(round(fd.precio_unitario*ncd.cantidad,2)*fd.descuento_pct,2) AS descuento
 ) b
 CROSS JOIN LATERAL (
 SELECT b.bruto,b.descuento,b.bruto-b.descuento AS neto,
 round((b.bruto-b.descuento)*fd.impuesto_pct,2) AS impuesto
 ) a
 WHERE f.estado='EMITIDA'
 ON CONFLICT(tipo_evento,linea_origen_id) DO UPDATE SET
 fecha_key=EXCLUDED.fecha_key,sucursal_key=EXCLUDED.sucursal_key,
 cliente_key=EXCLUDED.cliente_key,vendedor_key=EXCLUDED.vendedor_key,producto_key=EXCLUDED.producto_key,
 unidades=EXCLUDED.unidades,valor_bruto=EXCLUDED.valor_bruto,descuento=EXCLUDED.descuento,
 venta_neta=EXCLUDED.venta_neta,costo_venta=EXCLUDED.costo_venta,impuesto=EXCLUDED.impuesto,
 valor_facturado_con_impuesto=EXCLUDED.valor_facturado_con_impuesto;
 -- Inventario: una fila por movimiento, NO convertir a ventas.
 INSERT INTO dwh.fact_movimiento_inventario(movimiento_id,fecha_key,bodega_key,producto_key,tipo,cantidad_delta)
 SELECT m.movimiento_id,to_char(m.fecha_movimiento,'YYYYMMDD')::integer,b.bodega_key,p.producto_key,m.tipo,m.cantidad_delta
 FROM oltp.movimiento_inventario m
 JOIN dwh.dim_bodega b ON b.bodega_id=m.bodega_id
 JOIN dwh.dim_producto p ON p.producto_id=m.producto_id
 ON CONFLICT(movimiento_id) DO UPDATE SET fecha_key=EXCLUDED.fecha_key,bodega_key=EXCLUDED.bodega_key,
 producto_key=EXCLUDED.producto_key,tipo=EXCLUDED.tipo,cantidad_delta=EXCLUDED.cantidad_delta;
 INSERT INTO dwh.fact_meta(meta_id,mes_fecha_key,sucursal_key,vendedor_key,monto_meta)
 SELECT m.meta_id,to_char(m.mes,'YYYYMMDD')::integer,s.sucursal_key,v.vendedor_key,m.monto_meta
 FROM oltp.meta_mensual m JOIN dwh.dim_sucursal s ON s.sucursal_id=m.sucursal_id
 JOIN dwh.dim_vendedor v ON v.vendedor_id=m.vendedor_id
 ON CONFLICT(meta_id) DO UPDATE SET mes_fecha_key=EXCLUDED.mes_fecha_key,sucursal_key=EXCLUDED.sucursal_key,
 vendedor_key=EXCLUDED.vendedor_key,monto_meta=EXCLUDED.monto_meta;
 INSERT INTO dwh.fact_recaudo(pago_id,factura_id,fecha_key,sucursal_key,cliente_key,vendedor_key,monto_recaudado)
 SELECT pag.pago_id,pag.factura_id,to_char(pag.fecha_pago,'YYYYMMDD')::integer,
 s.sucursal_key,c.cliente_key,v.vendedor_key,pag.monto
 FROM oltp.pago pag JOIN oltp.factura f ON f.factura_id=pag.factura_id
 JOIN oltp.pedido pe ON pe.pedido_id=f.pedido_id
 JOIN dwh.dim_sucursal s ON s.sucursal_id=pe.sucursal_id
 JOIN dwh.dim_cliente c ON c.cliente_id=pe.cliente_id
 JOIN dwh.dim_vendedor v ON v.vendedor_id=pe.vendedor_id
 WHERE f.estado='EMITIDA'
 ON CONFLICT(pago_id) DO UPDATE SET fecha_key=EXCLUDED.fecha_key,sucursal_key=EXCLUDED.sucursal_key,
 cliente_key=EXCLUDED.cliente_key,vendedor_key=EXCLUDED.vendedor_key,monto_recaudado=EXCLUDED.monto_recaudado;
 SELECT count(*) INTO v_c1 FROM dwh.fact_venta;
 SELECT count(*) INTO v_c2 FROM dwh.fact_movimiento_inventario;
 SELECT count(*) INTO v_c3 FROM dwh.fact_meta;
 SELECT count(*) INTO v_c4 FROM dwh.fact_recaudo;
 UPDATE dwh.bitacora_carga SET finalizado=clock_timestamp(),estado='OK',
 filas_fact_venta=v_c1,filas_fact_inv=v_c2,filas_fact_meta=v_c3,filas_fact_recaudo=v_c4,mensaje='Carga completada'
 WHERE corrida_id=v_corrida;
EXCEPTION WHEN OTHERS THEN
 -- La excepcion revierte la transaccion invocante: esta marca no persiste.
 -- El orquestador externo debe registrar los fallos durables.
 RAISE;
END;$$;
-- Ejecucion: CALL dwh.cargar_retail360();
-- Prueba: repetir CALL y verificar que los conteos no aumenten sin nuevas fuentes.
