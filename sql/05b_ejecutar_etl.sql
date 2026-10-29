-- RETAIL 360 | 05b | Ejecutar carga definida en 05_etl_referencia.sql.
-- PRERREQUISITOS: ejecutar 01, 02, 04 y 05; verificar CSV y OLTP.
-- EJECUCION: psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/05b_ejecutar_etl.sql
-- Verificación: ejecutar 06_validar_dwh.sql y 09_pruebas_aceptacion.sql.
CALL dwh.cargar_retail360();
SELECT corrida_id, iniciado, finalizado, estado, filas_fact_venta,
       filas_fact_inv, filas_fact_meta, filas_fact_recaudo
FROM dwh.bitacora_carga ORDER BY corrida_id DESC LIMIT 1;
