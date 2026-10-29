-- RETAIL 360 | 13 | Ensayo REVERSIBLE de cambio de meta y carga posterior.
-- Prerrequisitos: 05 definido y cargado; el ensayo termina en ROLLBACK.
-- No ejecutar en producción. Ejecutar con psql -X -v ON_ERROR_STOP=1 -d retail360 -f ...
BEGIN;
SELECT 'ANTES' etapa, meta_id, monto_meta FROM oltp.meta_mensual WHERE meta_id=1;
UPDATE oltp.meta_mensual SET monto_meta=round(monto_meta*1.10,2) WHERE meta_id=1;
CALL dwh.cargar_retail360();
SELECT 'DURANTE' etapa, m.meta_id, m.monto_meta AS monto_dwh, o.monto_meta AS monto_oltp
FROM dwh.fact_meta m JOIN oltp.meta_mensual o USING(meta_id) WHERE m.meta_id=1;
ROLLBACK;
SELECT 'DESPUES_ROLLBACK' etapa, m.meta_id, m.monto_meta AS monto_dwh, o.monto_meta AS monto_oltp
FROM dwh.fact_meta m JOIN oltp.meta_mensual o USING(meta_id) WHERE m.meta_id=1;
-- Reto: diseñar un nuevo pago, nota crédito y pedido documentando precondiciones y rollback.
