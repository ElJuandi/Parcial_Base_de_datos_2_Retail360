# R3 · ETL/ELT en PostgreSQL

Etapa 3 · Laboratorio 3 · Producto 3.

**Entregables previstos**
- Mapa fuente → destino de cada atributo.
- Procedimiento y funciones PL/pgSQL **propios** con el contrato `CALL dwh.cargar_retail360()`.
- Diagrama del flujo ETL, bitácora y diagnóstico de errores.
- Salidas de `06`, `09`, `12` y `13`; comparación con `sql/05_etl_referencia.sql`.
- Propuesta de carga incremental (watermark, cambios tardíos, duplicados, auditoría).

**Aprobación:** fact_venta 30.750 · inventario 40.628 · metas 360 · recaudos 7.854 · diferencia neta 0,00 ·
idempotencia OK · ROLLBACK demostrado.
