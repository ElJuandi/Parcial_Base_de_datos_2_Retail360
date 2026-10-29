-- RETAIL 360 | 01 | Esquema transaccional. PostgreSQL 17.
-- Objetivo: entidades de ventas, facturacion, recaudo, inventario y metas.
-- Prerrequisito: conectarse EXCLUSIVAMENTE a la BD de laboratorio retail360.
-- No borra datos existentes. Ejecutar antes de 02_cargar_datos.psql.
CREATE SCHEMA IF NOT EXISTS oltp;

CREATE TABLE IF NOT EXISTS oltp.sucursal (
 sucursal_id integer PRIMARY KEY, nombre text NOT NULL UNIQUE, ciudad text NOT NULL
);
CREATE TABLE IF NOT EXISTS oltp.bodega (
 bodega_id integer PRIMARY KEY, sucursal_id integer REFERENCES oltp.sucursal(sucursal_id),
 nombre text NOT NULL UNIQUE, tipo text NOT NULL CHECK (tipo IN ('CENTRAL','LOCAL')),
 CHECK ((tipo='CENTRAL' AND sucursal_id IS NULL) OR (tipo='LOCAL' AND sucursal_id IS NOT NULL))
);
CREATE TABLE IF NOT EXISTS oltp.vendedor (
 vendedor_id integer PRIMARY KEY, sucursal_id integer NOT NULL REFERENCES oltp.sucursal(sucursal_id),
 nombre text NOT NULL, fecha_ingreso date NOT NULL
);
CREATE TABLE IF NOT EXISTS oltp.cliente (
 cliente_id integer PRIMARY KEY, nombre text NOT NULL, segmento text NOT NULL CHECK (segmento IN ('PERSONA','EMPRESA')),
 ciudad text NOT NULL, plazo_credito_dias integer NOT NULL CHECK(plazo_credito_dias BETWEEN 0 AND 90)
);
CREATE TABLE IF NOT EXISTS oltp.categoria (
 categoria_id integer PRIMARY KEY, nombre text NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS oltp.producto (
 producto_id integer PRIMARY KEY, categoria_id integer NOT NULL REFERENCES oltp.categoria(categoria_id),
 nombre text NOT NULL, costo_estandar numeric(14,2) NOT NULL CHECK (costo_estandar>=0),
 precio_lista numeric(14,2) NOT NULL CHECK(precio_lista > costo_estandar), activo boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS oltp.meta_mensual (
 meta_id integer PRIMARY KEY, vendedor_id integer NOT NULL REFERENCES oltp.vendedor(vendedor_id),
 sucursal_id integer NOT NULL REFERENCES oltp.sucursal(sucursal_id),
 mes date NOT NULL CHECK(EXTRACT(day FROM mes)=1), monto_meta numeric(16,2) NOT NULL CHECK(monto_meta>0),
 UNIQUE (vendedor_id,sucursal_id,mes)
);
CREATE TABLE IF NOT EXISTS oltp.pedido (
 pedido_id integer PRIMARY KEY, fecha_pedido date NOT NULL, cliente_id integer NOT NULL REFERENCES oltp.cliente(cliente_id),
 vendedor_id integer NOT NULL REFERENCES oltp.vendedor(vendedor_id),
 sucursal_id integer NOT NULL REFERENCES oltp.sucursal(sucursal_id),
 estado text NOT NULL CHECK(estado IN ('FACTURADO','PENDIENTE_STOCK','PENDIENTE_CREDITO','CANCELADO')),
 motivo text
);
CREATE TABLE IF NOT EXISTS oltp.pedido_detalle (
 pedido_detalle_id integer PRIMARY KEY, pedido_id integer NOT NULL REFERENCES oltp.pedido(pedido_id),
 producto_id integer NOT NULL REFERENCES oltp.producto(producto_id),
 cantidad integer NOT NULL CHECK(cantidad>0), UNIQUE(pedido_id,producto_id)
);
CREATE TABLE IF NOT EXISTS oltp.factura (
 factura_id integer PRIMARY KEY, pedido_id integer NOT NULL UNIQUE REFERENCES oltp.pedido(pedido_id),
 fecha_factura date NOT NULL, fecha_vencimiento date NOT NULL, estado text NOT NULL CHECK(estado IN ('EMITIDA','ANULADA')),
 CHECK(fecha_vencimiento >= fecha_factura)
);
CREATE TABLE IF NOT EXISTS oltp.factura_detalle (
 factura_detalle_id integer PRIMARY KEY, factura_id integer NOT NULL REFERENCES oltp.factura(factura_id),
 pedido_detalle_id integer NOT NULL UNIQUE REFERENCES oltp.pedido_detalle(pedido_detalle_id),
 producto_id integer NOT NULL REFERENCES oltp.producto(producto_id),
 cantidad integer NOT NULL CHECK(cantidad>0),
 precio_unitario numeric(14,2) NOT NULL CHECK(precio_unitario>0),
 costo_unitario numeric(14,2) NOT NULL CHECK(costo_unitario>=0),
 descuento_pct numeric(6,4) NOT NULL CHECK(descuento_pct BETWEEN 0 AND 0.80),
 impuesto_pct numeric(6,4) NOT NULL CHECK(impuesto_pct BETWEEN 0 AND 1)
);
CREATE TABLE IF NOT EXISTS oltp.nota_credito (
 nota_id integer PRIMARY KEY, factura_id integer NOT NULL REFERENCES oltp.factura(factura_id),
 fecha_nota date NOT NULL, motivo text NOT NULL,
 UNIQUE(nota_id,factura_id)
);
CREATE TABLE IF NOT EXISTS oltp.nota_credito_detalle (
 nota_detalle_id integer PRIMARY KEY, nota_id integer NOT NULL REFERENCES oltp.nota_credito(nota_id),
 factura_detalle_id integer NOT NULL REFERENCES oltp.factura_detalle(factura_detalle_id),
 cantidad integer NOT NULL CHECK(cantidad>0)
);
CREATE TABLE IF NOT EXISTS oltp.pago (
 pago_id integer PRIMARY KEY, factura_id integer NOT NULL REFERENCES oltp.factura(factura_id),
 fecha_pago date NOT NULL, monto numeric(16,2) NOT NULL CHECK(monto>0),
 medio text NOT NULL CHECK(medio IN ('TRANSFERENCIA','TARJETA','EFECTIVO'))
);
CREATE TABLE IF NOT EXISTS oltp.movimiento_inventario (
 movimiento_id bigint PRIMARY KEY, fecha_movimiento date NOT NULL,
 bodega_id integer NOT NULL REFERENCES oltp.bodega(bodega_id),
 producto_id integer NOT NULL REFERENCES oltp.producto(producto_id),
 tipo text NOT NULL CHECK(tipo IN ('APERTURA','COMPRA','VENTA','DEVOLUCION','TRASLADO_ENTRADA','TRASLADO_SALIDA','AJUSTE_ENTRADA','AJUSTE_SALIDA')),
 cantidad_delta integer NOT NULL CHECK(cantidad_delta<>0),
 referencia text NOT NULL,
 CHECK ((tipo IN ('APERTURA','COMPRA','DEVOLUCION','TRASLADO_ENTRADA','AJUSTE_ENTRADA') AND cantidad_delta>0)
      OR (tipo IN ('VENTA','TRASLADO_SALIDA','AJUSTE_SALIDA') AND cantidad_delta<0))
);
CREATE INDEX IF NOT EXISTS ix_pedido_fecha ON oltp.pedido(fecha_pedido);
CREATE INDEX IF NOT EXISTS ix_factura_fecha ON oltp.factura(fecha_factura);
CREATE INDEX IF NOT EXISTS ix_mov_bodega_producto_fecha ON oltp.movimiento_inventario(bodega_id,producto_id,fecha_movimiento);
CREATE INDEX IF NOT EXISTS ix_pago_factura ON oltp.pago(factura_id);
-- Verificacion: SELECT table_name FROM information_schema.tables WHERE table_schema='oltp' ORDER BY 1;
