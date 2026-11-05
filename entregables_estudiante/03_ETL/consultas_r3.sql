-- Retail 360 | R3 | Revisiones nuestras después de la carga.
-- Se corre después de las pruebas del profesor (05b, 06, 09, 12 y 13). No deja cambios.

-- 1. Bitácora: cada vez que se corre la carga queda una fila.
--    "+" = filas nuevas, "~" = filas que cambiaron. La primera carga mete todo y
--    las dos de la prueba 12 dan 0. La de la prueba 13 no aparece: esa prueba termina
--    en ROLLBACK y se deshace completa, bitácora incluida.
SELECT corrida_id, estado, filas_fact_venta, filas_fact_inv, filas_fact_meta, filas_fact_recaudo, mensaje
FROM dwh.bitacora_carga ORDER BY corrida_id;

-- 2. Paso 2 del ETL: revisión del origen antes de cargar (todo debe dar 0).
SELECT * FROM etl.revisar_origen();

-- 3. Paso 5 del ETL: el modelo cuadra con la operación, al centavo.
SELECT * FROM etl.conciliar();

-- 4. Facturas y notas crédito por separado: las notas restan y no borran la venta.
SELECT tipo_evento, count(*) AS filas, sum(unidades) AS unidades,
       sum(venta_neta) AS venta_neta, sum(venta_neta - costo_venta) AS margen_bruto
FROM dwh.fact_venta GROUP BY ROLLUP (tipo_evento) ORDER BY tipo_evento;

-- 5. Ejemplo: una línea vendida y su devolución, cada una con su propia fecha.
SELECT v.tipo_evento, v.factura_id, f.fecha, v.unidades, v.venta_neta
FROM dwh.fact_venta v JOIN dwh.dim_fecha f ON f.fecha_key = v.fecha_key
WHERE v.factura_id = (SELECT min(factura_id) FROM dwh.fact_venta WHERE tipo_evento = 'NOTA_CREDITO')
  AND v.producto_key IN (SELECT producto_key FROM dwh.fact_venta
                         WHERE tipo_evento = 'NOTA_CREDITO'
                           AND factura_id = (SELECT min(factura_id) FROM dwh.fact_venta WHERE tipo_evento = 'NOTA_CREDITO'))
ORDER BY f.fecha;

-- 6. Las columnas que agregamos en R2 quedaron llenas (todo en 0 = sin vacíos).
SELECT
  (SELECT count(*) FROM dwh.dim_fecha    WHERE dia IS NULL OR nombre_dia IS NULL OR nombre_mes IS NULL) AS fecha_sin_nombres,
  (SELECT count(*) FROM dwh.dim_sucursal WHERE region IS NULL)                                       AS sucursal_sin_region,
  (SELECT count(*) FROM dwh.dim_bodega   WHERE tipo = 'LOCAL' AND sucursal_key IS NULL)               AS bodega_local_sin_sucursal,
  (SELECT count(*) FROM dwh.dim_vendedor WHERE sucursal_key IS NULL OR fecha_ingreso IS NULL)         AS vendedor_incompleto,
  (SELECT count(*) FROM dwh.dim_cliente  WHERE plazo_credito_dias IS NULL)                            AS cliente_sin_plazo,
  (SELECT count(*) FROM dwh.dim_producto WHERE costo_estandar IS NULL OR precio_lista IS NULL)        AS producto_sin_precios;

SELECT sucursal_id, nombre, ciudad, region FROM dwh.dim_sucursal ORDER BY sucursal_id;

-- 7. Pruebas negativas: el ETL debe DETENERSE cuando algo está mal.
--    Cada prueba daña algo a propósito dentro de un bloque que al final se deshace solo.

-- 7a. Un pago con fecha anterior a su factura -> la revisión del origen detiene la carga.
DO $$
BEGIN
    UPDATE oltp.pago SET fecha_pago = DATE '2020-01-01' WHERE pago_id = (SELECT min(pago_id) FROM oltp.pago);
    CALL dwh.cargar_retail360();
    RAISE EXCEPTION 'FALLO: la carga no se detuvo con un pago mal fechado';
EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'Carga detenida%' THEN
        RAISE NOTICE 'PRUEBA NEGATIVA 1 OK (origen con error): %', SQLERRM;
    ELSE
        RAISE;
    END IF;
END $$;

-- 7b. Una fila de venta de más en el modelo -> la conciliación lo detecta y deshace la carga.
DO $$
BEGIN
    INSERT INTO dwh.fact_venta (tipo_evento, linea_origen_id, factura_id, fecha_key, sucursal_key, cliente_key,
        vendedor_key, producto_key, unidades, valor_bruto, descuento, venta_neta, costo_venta, impuesto,
        valor_facturado_con_impuesto)
    SELECT 'FACTURA', -1, factura_id, fecha_key, sucursal_key, cliente_key, vendedor_key, producto_key,
           unidades, valor_bruto, descuento, venta_neta, costo_venta, impuesto, valor_facturado_con_impuesto
    FROM dwh.fact_venta ORDER BY venta_key LIMIT 1;
    CALL dwh.cargar_retail360();
    RAISE EXCEPTION 'FALLO: la carga no notó la fila de más';
EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'Carga deshecha%' THEN
        RAISE NOTICE 'PRUEBA NEGATIVA 2 OK (modelo descuadrado): %', SQLERRM;
    ELSE
        RAISE;
    END IF;
END $$;

-- 8. Después de las pruebas negativas todo sigue igual que antes.
SELECT (SELECT count(*) FROM dwh.fact_venta) AS fact_venta,
       (SELECT count(*) FROM dwh.fact_movimiento_inventario) AS fact_inventario,
       (SELECT count(*) FROM dwh.fact_meta) AS fact_meta,
       (SELECT count(*) FROM dwh.fact_recaudo) AS fact_recaudo,
       (SELECT sum(venta_neta) FROM dwh.fact_venta) AS venta_neta,
       (SELECT count(*) FROM oltp.pago WHERE fecha_pago < DATE '2024-01-01') AS pagos_mal_fechados;
