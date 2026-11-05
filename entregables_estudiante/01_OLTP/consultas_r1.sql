-- Retail 360 | R1 | Consultas de revisión de la base de la operación (OLTP)
-- Se corren después de los scripts 01, 02 y 03 del profesor. No cambian ningún dato.

-- 1. ¿Se cargaron todas las tablas con la cantidad que dice la guía?
SELECT tabla, filas, esperado, CASE WHEN filas = esperado THEN 'OK' ELSE 'REVISAR' END AS estado
FROM (VALUES
  ('sucursal',             (SELECT count(*) FROM oltp.sucursal),                  3),
  ('bodega',               (SELECT count(*) FROM oltp.bodega),                    4),
  ('vendedor',             (SELECT count(*) FROM oltp.vendedor),                 15),
  ('cliente',              (SELECT count(*) FROM oltp.cliente),                1500),
  ('categoria',            (SELECT count(*) FROM oltp.categoria),                12),
  ('producto',             (SELECT count(*) FROM oltp.producto),                400),
  ('meta_mensual',         (SELECT count(*) FROM oltp.meta_mensual),            360),
  ('pedido',               (SELECT count(*) FROM oltp.pedido),                12000),
  ('pedido_detalle',       (SELECT count(*) FROM oltp.pedido_detalle),        36992),
  ('factura',              (SELECT count(*) FROM oltp.factura),               10019),
  ('factura_detalle',      (SELECT count(*) FROM oltp.factura_detalle),       30224),
  ('nota_credito',         (SELECT count(*) FROM oltp.nota_credito),            526),
  ('nota_credito_detalle', (SELECT count(*) FROM oltp.nota_credito_detalle),    526),
  ('pago',                 (SELECT count(*) FROM oltp.pago),                   7854),
  ('movimiento_inventario',(SELECT count(*) FROM oltp.movimiento_inventario), 40628)
) AS t(tabla, filas, esperado);

-- 2. Del pedido al pago: no todo pedido se factura y no toda factura se cobra.
SELECT estado AS estado_pedido, count(*) AS pedidos
FROM oltp.pedido GROUP BY estado ORDER BY pedidos DESC;

WITH total_factura AS (
  SELECT factura_id,
         sum( round(precio_unitario * cantidad, 2)
            - round(round(precio_unitario * cantidad, 2) * descuento_pct, 2)
            + round((round(precio_unitario * cantidad, 2)
                    - round(round(precio_unitario * cantidad, 2) * descuento_pct, 2)) * impuesto_pct, 2)
         ) AS total
  FROM oltp.factura_detalle GROUP BY factura_id
), pagos AS (
  SELECT factura_id, sum(monto) AS pagado FROM oltp.pago GROUP BY factura_id
)
SELECT count(*)                                              AS facturas,
       count(p.factura_id)                                   AS facturas_con_pago,
       count(*) - count(p.factura_id)                        AS facturas_sin_pago,
       count(*) FILTER (WHERE p.pagado < t.total - 0.01)     AS pagadas_en_parte,
       count(*) FILTER (WHERE p.pagado >= t.total - 0.01)    AS pagadas_completas
FROM total_factura t LEFT JOIN pagos p USING (factura_id);

-- 3. Inventario actual por bodega y total de la empresa.
SELECT b.nombre AS bodega, b.tipo, sum(m.cantidad_delta) AS unidades_en_bodega
FROM oltp.movimiento_inventario m JOIN oltp.bodega b USING (bodega_id)
GROUP BY b.nombre, b.tipo
UNION ALL
SELECT 'TOTAL EMPRESA', '', sum(cantidad_delta) FROM oltp.movimiento_inventario
ORDER BY 1;

-- Los traslados sacan de una bodega y meten en otra: en total deben sumar 0.
SELECT tipo, count(*) AS movimientos, sum(cantidad_delta) AS unidades
FROM oltp.movimiento_inventario WHERE tipo LIKE 'TRASLADO%'
GROUP BY tipo
UNION ALL
SELECT 'SUMA DE TRASLADOS', count(*), sum(cantidad_delta)
FROM oltp.movimiento_inventario WHERE tipo LIKE 'TRASLADO%';

-- 4. Descuentos: cuántas líneas de factura llevan descuento y cuál es el más alto.
SELECT count(*) AS lineas_factura,
       count(*) FILTER (WHERE descuento_pct > 0) AS lineas_con_descuento,
       round(100.0 * count(*) FILTER (WHERE descuento_pct > 0) / count(*), 1) AS porcentaje_con_descuento,
       max(descuento_pct) * 100 AS descuento_maximo_pct
FROM oltp.factura_detalle;
