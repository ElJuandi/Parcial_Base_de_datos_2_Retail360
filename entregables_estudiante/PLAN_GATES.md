# Plan de gates · Retail 360

Regla general: **ningún gate se aprueba si el anterior no pasó**, y ningún gate se cierra sin su
entrada en el registro de IA (`IA/registro_ia.md`): intento propio → prompt → validación con SQL → decisión.

Fuentes cruzadas para este plan: guía oficial (`documentacion/Guia_Laboratorio_Retail360.docx`),
scripts del paquete (`sql/`), infografía del curso (6 etapas y 5 productos entregables).

| Gate | Etapa (infografía) | Qué se hace | Condición de aprobación | Carpeta |
|---|---|---|---|---|
| **R0** Arranque | — | Repositorio, entorno (PostgreSQL, Python, Power BI), integridad del paquete, base `retail360`, plantilla de registro IA | `validar_csv.py` = "Validaciones: OK"; SHA-256 de `data/` coincide; conexión a `retail360`; versiones registradas | `00_ARRANQUE` |
| **R1** OLTP | 1. Modelo relacional | E-R propio antes de leer el script; ≥ 10 reglas de negocio; scripts 01–03; por qué pedido ≠ factura ≠ pago; inventario por bodega y efecto de los traslados | Los 4 controles de `03_verificar_oltp.sql` = 0 y conteos iguales a la guía (sección 2.3) | `01_OLTP` |
| **R2** DWH | 2. Modelo dimensional | ≥ 8 preguntas gerenciales; granularidad por hecho; matriz bus; aditividad; diccionario; diagrama de constelación; claves sustitutas; propuesta SCD2 | Script 04 ejecutado y contrastado con el diseño; demostración SQL de la multiplicación de metas y su corrección | `02_DWH` |
| **R3** ETL | 3. ETL/ELT en PostgreSQL | Mapa fuente→destino; **procedimiento y funciones propias** con contrato `CALL dwh.cargar_retail360()`; diagrama del flujo; bitácora; propuesta de carga incremental; comparación con la referencia del docente | 06, 09, 12 y 13 pasan: fact_venta 30.750 · inventario 40.628 · metas 360 · recaudos 7.854 · diferencia neta 0,00 · ROLLBACK demostrado | `03_ETL` |
| **R4** Scripts SQL | 1–3 (producto 1) | Retos C01–C12 de `sql/11`; vistas 07 y 10; exportación 08; ≥ 5 evidencias con interpretación de negocio | ≥ 10 retos (meta: 12) con resultado e interpretación; 4 CSV en `export/` con su grano documentado | `04_KPI/retos_sql` |
| **R5** KPI | 4. KPI y visualizaciones | ≥ 12 KPI de 5 perspectivas (fórmula, unidad, grano, hecho, filtros, NC, nulos); matriz KPI→hecho→filtro; casos de prueba calculados a mano; 4 wireframes; visualizaciones engañosas | Catálogo aprobado por el grupo **antes** de abrir Power BI | `04_KPI` |
| **R6** Power BI | 5. Power BI + IA | Conexión a `retail360`; relaciones 1:N desde dimensiones; medidas DAX explícitas; 4 páginas (comercial, stock, vendedores/metas, facturación/recaudos) | ≥ 7 KPI iguales a SQL con los mismos filtros (matriz de equivalencia: columnas SQL y Power BI) | `05_VISUALIZACION/powerbi` |
| **R7** HTML con IA | 5. Power BI + IA | HTML único **offline** (sin CDN, API ni fetch) desde los 4 CSV y el contrato de KPI; prompts registrados (IA-07) | Abre sin internet; filtros y definiciones visibles; matriz de equivalencia SQL = Power BI = HTML completa | `05_VISUALIZACION/html` |
| **R8** Interpretación | 6. Interpretación | 5 fichas de hallazgo (≥ 3 cruzan dos procesos); 4 escenarios paradójicos; HECHO / HIPÓTESIS / INFERENCIA / DECISIÓN; 3 decisiones con responsable, riesgo y KPI | Cada hallazgo se reproduce con una consulta SQL | `06_INTERPRETACION` |
| **R9** Cierre | Producto 5 | Informe final; registro IA completo; preguntas obligatorias de cierre; simulacro de defensa (IA-09); README reproducible; tag `entrega-final` | Un tercero clona el repositorio y reproduce el resultado desde cero | `06_INTERPRETACION` |

## Productos entregables (infografía) → gates

| Producto | Gates | Peso en la rúbrica |
|---|---|---|
| 1. Scripts SQL documentados | R1, R3, R4 | 15 % |
| 2. Modelo dimensional | R2 | 20 % |
| 3. Procedimientos ETL | R3 | 20 % |
| 4. Dashboard en Power BI | R5, R6 | 15 % KPI + parte de 15 % |
| 5. HTML analítico + informe final | R7, R8, R9 | parte de 15 % + 15 % |

## Flujo de trabajo en GitHub

- Rama `main`: solo recibe gates aprobados.
- Una rama por gate (`r1-oltp`, `r2-dwh`, …) cuando el trabajo sea largo.
- Al aprobar un gate: commit + tag `R#-aprobado` (por ejemplo `R0-aprobado`).
