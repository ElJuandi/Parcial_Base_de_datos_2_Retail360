# Plan de trabajo por etapas

Regla del grupo: no pasamos a la siguiente etapa hasta que la actual esté terminada y revisada.
Cada vez que usemos IA, lo anotamos en `IA/registro_ia.md`.

| Etapa | Qué hacemos | Cuándo la damos por terminada | Carpeta | Estado |
|---|---|---|---|---|
| R0 Arranque | Dejamos listo el repositorio y el computador principal (PostgreSQL, Python y Power BI). Creamos la base `retail360`. | El script de verificación dice OK. | `00_ARRANQUE` | Listo |
| R1 OLTP | Dibujamos el diagrama de las 15 tablas, escribimos las reglas del negocio y cargamos los datos. | Las revisiones del script 03 dan 0 y los conteos coinciden con la guía. | `01_OLTP` | Listo |
| R2 Modelo dimensional | Definimos las preguntas del negocio, las tablas de hechos y de dimensiones y armamos el modelo en estrella. | El modelo queda creado y mostramos por qué la meta no se puede repetir en cada venta. | `02_DWH` | Listo |
| R3 ETL | Hacemos nuestro propio procedimiento para pasar los datos al modelo de análisis. | Las pruebas del profesor (06, 09, 12 y 13) pasan y las cifras cuadran. | `03_ETL` | Listo |
| R4 Consultas | Resolvemos los 12 retos SQL y exportamos los 4 archivos para el tablero. | Mínimo 10 retos resueltos y explicados. | `04_KPI` | Listo |
| R5 Indicadores | Definimos los indicadores (al final fueron 15) con su fórmula y dibujamos cómo se verán los tableros. | El grupo aprueba los indicadores antes de abrir Power BI. | `04_KPI` | Listo |
| R6 Power BI | Armamos el tablero con 4 páginas. | 7 indicadores dan igual en Power BI y en SQL (comparamos los 15). | `05_VISUALIZACION` | Listo |
| R7 Tablero web | Hacemos con IA una página que funcione sin internet. | Da las mismas cifras que SQL y Power BI. | `05_VISUALIZACION/web` | Listo |
| R8 Hallazgos | Sacamos 5 hallazgos con evidencia y 3 decisiones. | Cada hallazgo se puede comprobar con una consulta. | `06_INTERPRETACION` | Listo |
| R9 Cierre | Informe final. | Otra persona puede seguir el README y llegar al mismo resultado. | `07_INFORME` | Listo |

Antes de trabajar en cualquier computador: Fetch y Pull en GitHub Desktop.
Al terminar algo: Commit y Push.

## Cómo terminó

Las 10 etapas quedaron listas. El resultado de cada una está en el README de su carpeta, y el
resumen de todo en `07_INFORME/informe_final.md`.
