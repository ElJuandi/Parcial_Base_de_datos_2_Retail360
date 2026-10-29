# Registro de decisiones técnicas

| # | Fecha | Decisión | Motivo | Estado |
|---|---|---|---|---|
| D01 | 2026-10-29 | La fuente oficial es la guía `Guia_Laboratorio_Retail360.docx` y los scripts del paquete. | Un documento externo ("Informe técnico – sábana analítica") usa tablas `tbl_*`, facturas "Anulado", omite notas crédito y propone HTML con CDN: contradice el paquete. Solo se reutilizan ideas (patrón DAX `SUMX(DISTINCT…)`, controles de calidad). | Vigente |
| D02 | 2026-10-29 | Los archivos del docente (`sql/`, `data/`, `documentacion/`, `*.py`) no se modifican. El trabajo propio va en `entregables_estudiante/`. | Los comandos `psql` usan rutas relativas desde la raíz y los CSV se verifican con SHA-256. | Vigente |
| D03 | 2026-10-29 | `sql/05_etl_referencia.sql` es solo referencia de autovalidación; el grupo implementa su propio ETL en `03_ETL/` con el mismo contrato `CALL dwh.cargar_retail360()`. | La guía permite que el docente reserve ese archivo y evalúa la implementación propia. | Vigente |
| D04 | 2026-10-29 | Los retos de `sql/11` se resuelven en el gate R4 (después del ETL). | Sus prerrequisitos son 01–05, 07 y 10: consultan el DWH, aunque la guía los ubica en el Laboratorio 1. | Vigente |
| D05 | 2026-10-29 | La guía pide PostgreSQL 17; se registra la versión real usada. | Ensayo previo de los 15 scripts sin errores en PostgreSQL 16; se espera compatibilidad con la versión instalada. Confirmar en R0. | Por confirmar |
| D06 | 2026-10-29 | El HTML final será 100 % offline (sin CDN). | Requisito explícito de la guía (Laboratorio 5, paso 11). | Vigente |
| D07 | — | Conformación del grupo. | La guía permite parejas o máximo 3 integrantes. | Pendiente |

## Observaciones del paquete (detectadas en el análisis inicial)

- `generar_datos.py` menciona un archivo `LIMITACIONES.md` que no viene en el ZIP.
- Las vistas 07 y 10 tienen la fecha de corte fija en **2026-09-30**.
- Los clientes PERSONA tienen plazo de crédito de 0 días: casi toda la cartera pendiente aparece como "vencida". Debe explicarse en la interpretación (R8), no tomarse como hallazgo sin contexto.
- `vw_recaudos_mensuales` exporta `cliente_key` (clave sustituta), no `cliente_id`.
