RETAIL 360 — LABORATORIO INTEGRADOR (EDICIÓN 28-10-2026)

INICIO: leer documentacion/Guia_Laboratorio_Retail360.docx.

EJECUCION DESDE LA CARPETA RAIZ (Windows PowerShell):
  psql -X -v ON_ERROR_STOP=1 -d postgres -f sql/00_crear_base.sql   (SOLO UNA VEZ)
  py -3.12 validar_csv.py
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/01_esquema_oltp.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/02_cargar_datos.psql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/03_verificar_oltp.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/04_esquema_dwh.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/05_etl_referencia.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/05b_ejecutar_etl.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/06_validar_dwh.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/09_pruebas_aceptacion.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/12_prueba_idempotencia.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/07_vistas_analiticas.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/10_cartera_corte.sql
  psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/08_exportar_analitica.psql

IMPORTANTE:
- 02_cargar_datos.psql ejecuta TRUNCATE. SOLO en base aislada retail360.
- Ejecutar desde la raíz del paquete para resolver data/ y export/.
- 05_etl_referencia.sql contiene una solución orientativa: el docente puede reservarlo.
- 11_retos_consultas_estudiante.sql contiene ejercicios sin resolver.
- Los archivos data/ son sintéticos: no contienen información personal real.
- Los scripts de base requieren prueba final en PostgreSQL 17 del estudiante.

CSV VERIFICADOS (semilla 360): facturas 10019; líneas de factura 30224;
notas 526; movimientos 40628; pagos 7854; metas 360.
El DWH incorpora 30750 eventos en fact_venta (facturas + NC).
