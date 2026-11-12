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

## Las etapas

Trabajamos por etapas (gates) y no pasamos a la siguiente hasta terminar bien la anterior.
Todas están terminadas.

| Etapa | Qué es | Carpeta | Qué se corre | Estado |
|---|---|---|---|---|
| R0 | Preparar el equipo y revisar que todo funcione | `00_ARRANQUE` | `verificar_entorno.bat` | Listo |
| R1 | Base de datos de la operación | `01_OLTP` | `ejecutar_r1.bat` | Listo |
| R2 | Modelo para análisis | `02_DWH` | `ejecutar_r2.bat` | Listo |
| R3 | Pasar los datos al modelo de análisis (ETL) | `03_ETL` | `ejecutar_r3.bat` | Listo |
| R4 | Consultas SQL y archivos para el tablero | `04_KPI` | `ejecutar_r4.bat` | Listo |
| R5 | Indicadores (KPI) | `04_KPI` | `ejecutar_r5.bat` | Listo |
| R6 | Tablero en Power BI | `05_VISUALIZACION` | Abrir `Retail360.pbix` | Listo |
| R7 | Tablero web hecho con IA | `05_VISUALIZACION/web` | `ejecutar_r7.bat` | Listo |
| R8 | Hallazgos y decisiones | `06_INTERPRETACION` | `ejecutar_r8.bat` | Listo |
| R9 | Informe final | `07_INFORME` | Solo leer | Listo |

Todas las carpetas están dentro de `entregables_estudiante/`. Cada una tiene su README con lo
que hay adentro y el resultado que nos dio.

**Para leer primero:** el informe final, en `entregables_estudiante/07_INFORME/informe_final.md`.

Otros archivos útiles:

- `entregables_estudiante/PLAN_GATES.md` - el plan de etapas.
- `entregables_estudiante/DECISIONES.md` - lo que decidimos en el camino y por qué.
- `entregables_estudiante/IA/registro_ia.md` - cómo usamos la IA en cada etapa.

## Cómo repetir todo

Se necesita PostgreSQL con una base llamada `retail360`, Python y Power BI Desktop.

1. Clonar el repositorio.
2. Dar doble clic a cada archivo `.bat` de la tabla, en orden, de R0 a R8. Cada uno pide la
   contraseña de PostgreSQL y guarda lo que salió en la carpeta `salidas` de su etapa.
3. Ojo: `ejecutar_r1.bat` borra y vuelve a cargar los datos de la operación. Por eso hay que
   correr después R2 y R3 otra vez.
4. Al terminar R7 queda la página `05_VISUALIZACION/web/tablero_retail360.html`. Se abre con
   doble clic y funciona sin internet.
5. Para Power BI, abrir `05_VISUALIZACION/Retail360.pbix` y darle Actualizar. Se conecta a
   `localhost`, base `retail360`.

Si todo salió bien, los números deben ser los mismos que aparecen en el informe.

El orden de los scripts originales del profesor está en `README_EJECUCION.txt`.
