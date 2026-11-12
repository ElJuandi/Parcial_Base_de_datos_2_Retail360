# Retail 360 - Parcial de Bases de Datos II

Universidad de Manizales · Ingeniería de Sistemas y Telecomunicaciones

Este es nuestro trabajo del laboratorio integrador Retail 360. La idea es tomar los datos de una
tienda de tecnología (ventas, inventario, pagos y metas), organizarlos para poder analizarlos y
terminar con tableros en Power BI y en una página web que ayuden a tomar decisiones.

La pregunta que queremos responder: ¿por qué la empresa vende más pero gana menos, se queda sin
productos en algunas bodegas y no logra cobrar todo lo que factura?

## Integrantes

- Juan Diego Ortiz
- Adrian Daniel Argotte
- Miguel Andrés Pava
- Jerónimo Soto
- David González

## Qué hay en cada carpeta

- `documentacion/` - la guía del profesor.
- `sql/` - los scripts que entregó el profesor.
- `data/` - los datos de la tienda en archivos CSV.
- `export/` - aquí quedan los archivos que sacamos para el tablero web.
- `entregables_estudiante/` - todo lo que hacemos nosotros, separado por etapas.

Lo del profesor no se modifica. Nuestro trabajo va todo dentro de `entregables_estudiante/`.

## Cómo vamos

Trabajamos por etapas (gates). No pasamos a la siguiente hasta terminar bien la anterior.

| Etapa | Qué es | Estado |
|---|---|---|
| R0 | Preparar el equipo y revisar que todo funcione | Listo |
| R1 | Base de datos de la operación (OLTP) | Listo |
| R2 | Modelo para análisis (estrella) | Listo |
| R3 | Pasar los datos de un modelo al otro (ETL) | Listo |
| R4 | Consultas SQL y archivos para el tablero | Listo |
| R5 | Indicadores (KPI) | Listo |
| R6 | Tablero en Power BI | Listo |
| R7 | Tablero web hecho con IA | Listo |
| R8 | Hallazgos y decisiones | Siguiente |
| R9 | Informe final y sustentación | Pendiente |

El detalle de cada etapa está en `entregables_estudiante/PLAN_GATES.md`.

## Cómo correrlo

Se trabaja con PostgreSQL instalado en el computador. Para revisar que todo esté listo, se da doble
clic a `entregables_estudiante/00_ARRANQUE/verificar_entorno.bat` y se escribe la contraseña de
PostgreSQL cuando la pida. El orden de los scripts del profesor está en `README_EJECUCION.txt`.
