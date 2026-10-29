-- RETAIL 360 | 04 | Modelo dimensional (bus matrix con dimensiones conformadas).
-- Ejecutar luego de validar la carga OLTP. Esquema sin SCD2 (desafio adicional).
CREATE SCHEMA IF NOT EXISTS dwh;
CREATE TABLE IF NOT EXISTS dwh.dim_fecha (
 fecha_key integer PRIMARY KEY, fecha date NOT NULL UNIQUE,
 anio integer NOT NULL, mes_num integer NOT NULL, mes_inicio date NOT NULL,
 trimestre integer NOT NULL, anio_mes char(7) NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.dim_sucursal (
 sucursal_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 sucursal_id integer NOT NULL UNIQUE, nombre text NOT NULL, ciudad text NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.dim_bodega (
 bodega_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 bodega_id integer NOT NULL UNIQUE, nombre text NOT NULL, tipo text NOT NULL,
 sucursal_id integer NULL
);
CREATE TABLE IF NOT EXISTS dwh.dim_cliente (
 cliente_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 cliente_id integer NOT NULL UNIQUE, nombre text NOT NULL, segmento text NOT NULL, ciudad text NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.dim_vendedor (
 vendedor_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 vendedor_id integer NOT NULL UNIQUE, nombre text NOT NULL, sucursal_actual_id integer NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.dim_producto (
 producto_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 producto_id integer NOT NULL UNIQUE, nombre text NOT NULL,
 categoria_id integer NOT NULL, categoria text NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.fact_venta (
 venta_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 tipo_evento text NOT NULL CHECK(tipo_evento IN ('FACTURA','NOTA_CREDITO')),
 linea_origen_id integer NOT NULL,
 factura_id integer NOT NULL,
 fecha_key integer NOT NULL REFERENCES dwh.dim_fecha(fecha_key),
 sucursal_key integer NOT NULL REFERENCES dwh.dim_sucursal(sucursal_key),
 cliente_key integer NOT NULL REFERENCES dwh.dim_cliente(cliente_key),
 vendedor_key integer NOT NULL REFERENCES dwh.dim_vendedor(vendedor_key),
 producto_key integer NOT NULL REFERENCES dwh.dim_producto(producto_key),
 unidades integer NOT NULL, valor_bruto numeric(18,2) NOT NULL,
 descuento numeric(18,2) NOT NULL, venta_neta numeric(18,2) NOT NULL,
 costo_venta numeric(18,2) NOT NULL, impuesto numeric(18,2) NOT NULL,
 valor_facturado_con_impuesto numeric(18,2) NOT NULL,
 UNIQUE(tipo_evento,linea_origen_id)
);
CREATE TABLE IF NOT EXISTS dwh.fact_movimiento_inventario (
 movimiento_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 movimiento_id bigint NOT NULL UNIQUE,
 fecha_key integer NOT NULL REFERENCES dwh.dim_fecha(fecha_key),
 bodega_key integer NOT NULL REFERENCES dwh.dim_bodega(bodega_key),
 producto_key integer NOT NULL REFERENCES dwh.dim_producto(producto_key),
 tipo text NOT NULL, cantidad_delta integer NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.fact_meta (
 meta_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 meta_id integer NOT NULL UNIQUE,
 mes_fecha_key integer NOT NULL REFERENCES dwh.dim_fecha(fecha_key),
 sucursal_key integer NOT NULL REFERENCES dwh.dim_sucursal(sucursal_key),
 vendedor_key integer NOT NULL REFERENCES dwh.dim_vendedor(vendedor_key),
 monto_meta numeric(18,2) NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.fact_recaudo (
 recaudo_key bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 pago_id integer NOT NULL UNIQUE, factura_id integer NOT NULL,
 fecha_key integer NOT NULL REFERENCES dwh.dim_fecha(fecha_key),
 sucursal_key integer NOT NULL REFERENCES dwh.dim_sucursal(sucursal_key),
 cliente_key integer NOT NULL REFERENCES dwh.dim_cliente(cliente_key),
 vendedor_key integer NOT NULL REFERENCES dwh.dim_vendedor(vendedor_key),
 monto_recaudado numeric(18,2) NOT NULL
);
CREATE TABLE IF NOT EXISTS dwh.bitacora_carga (
 corrida_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 iniciado timestamp NOT NULL DEFAULT clock_timestamp(),
 finalizado timestamp, estado text NOT NULL,
 filas_fact_venta bigint, filas_fact_inv bigint, filas_fact_meta bigint, filas_fact_recaudo bigint,
 mensaje text
);
-- Consulta exploratoria: SELECT * FROM information_schema.tables WHERE table_schema='dwh';
