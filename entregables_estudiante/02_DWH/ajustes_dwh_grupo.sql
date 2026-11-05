-- Retail 360 | R2 | Ajustes del grupo al modelo de análisis
-- Se corre DESPUÉS de sql/04_esquema_dwh.sql (el del profesor, que no modificamos).
-- Agrega columnas que pide la infografía del curso y que los datos sí permiten llenar.
-- Las columnas nuevas aceptan vacío para no romper el ETL de referencia del profesor;
-- nuestro ETL (R3) es el que las llena. Se puede correr varias veces sin problema.

-- Fecha: día del mes y nombres para mostrar en los tableros.
ALTER TABLE dwh.dim_fecha ADD COLUMN IF NOT EXISTS dia integer;
ALTER TABLE dwh.dim_fecha ADD COLUMN IF NOT EXISTS nombre_dia text;
ALTER TABLE dwh.dim_fecha ADD COLUMN IF NOT EXISTS nombre_mes text;

-- Sucursal: región. No viene en los datos; la sacamos de la ciudad
-- (Manizales y Pereira = Eje Cafetero, Medellín = Antioquia).
ALTER TABLE dwh.dim_sucursal ADD COLUMN IF NOT EXISTS region text;

-- Bodega y vendedor: enlace a la dimensión sucursal (la central queda sin sucursal).
ALTER TABLE dwh.dim_bodega ADD COLUMN IF NOT EXISTS sucursal_key integer REFERENCES dwh.dim_sucursal(sucursal_key);
ALTER TABLE dwh.dim_vendedor ADD COLUMN IF NOT EXISTS sucursal_key integer REFERENCES dwh.dim_sucursal(sucursal_key);
ALTER TABLE dwh.dim_vendedor ADD COLUMN IF NOT EXISTS fecha_ingreso date;

-- Cliente: días de crédito, lo necesitamos para entender la cartera.
ALTER TABLE dwh.dim_cliente ADD COLUMN IF NOT EXISTS plazo_credito_dias integer;

-- Producto: costo y precio de lista del catálogo.
ALTER TABLE dwh.dim_producto ADD COLUMN IF NOT EXISTS costo_estandar numeric(14,2);
ALTER TABLE dwh.dim_producto ADD COLUMN IF NOT EXISTS precio_lista numeric(14,2);

-- Lo que NO agregamos: el "cargo" del vendedor que sale en la infografía,
-- porque ese dato no existe en la base de la operación.
