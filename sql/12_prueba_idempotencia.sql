-- RETAIL 360 | 12 | Test de idempotencia de carga completa.
-- PRERREQUISITOS: primera carga completada, 05_etl_referencia.sql creado.
-- Ejecucion: psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/12_prueba_idempotencia.sql
-- Crea tabla TEMP y ejecuta el procedimiento dos veces; NO modifica origen OLTP.
BEGIN;
CREATE TEMP TABLE baseline_retail360 ON COMMIT DROP AS
 SELECT (SELECT count(*) FROM dwh.fact_venta) AS ventas_filas,
        (SELECT coalesce(sum(venta_neta),0) FROM dwh.fact_venta) AS ventas_total,
        (SELECT count(*) FROM dwh.fact_movimiento_inventario) AS inv_filas,
        (SELECT count(*) FROM dwh.fact_meta) AS metas_filas,
        (SELECT coalesce(sum(monto_meta),0) FROM dwh.fact_meta) AS metas_total,
        (SELECT count(*) FROM dwh.fact_recaudo) AS recaudos_filas,
        (SELECT coalesce(sum(monto_recaudado),0) FROM dwh.fact_recaudo) AS recaudos_total;
CALL dwh.cargar_retail360();
CALL dwh.cargar_retail360();
DO $$
DECLARE b record;
BEGIN
 SELECT * INTO b FROM baseline_retail360;
 IF b.ventas_filas<>(SELECT count(*) FROM dwh.fact_venta)
 OR b.ventas_total<>(SELECT coalesce(sum(venta_neta),0) FROM dwh.fact_venta)
 OR b.inv_filas<>(SELECT count(*) FROM dwh.fact_movimiento_inventario)
 OR b.metas_filas<>(SELECT count(*) FROM dwh.fact_meta)
 OR b.metas_total<>(SELECT coalesce(sum(monto_meta),0) FROM dwh.fact_meta)
 OR b.recaudos_filas<>(SELECT count(*) FROM dwh.fact_recaudo)
 OR b.recaudos_total<>(SELECT coalesce(sum(monto_recaudado),0) FROM dwh.fact_recaudo)
 THEN RAISE EXCEPTION 'Prueba idempotencia FALLIDA: cambió un conteo o importe sin cambios OLTP';
 END IF;
 RAISE NOTICE 'PRUEBA IDEMPOTENCIA OK: conteos e importes preservados en dos reejecuciones';
END $$;
COMMIT;
-- NOTA: los registros de bitácora aumentan: registrar ejecuciones es un efecto intencional.
-- La prueba demuestra repetibilidad sobre origen INALTERADO, no incrementalidad.
