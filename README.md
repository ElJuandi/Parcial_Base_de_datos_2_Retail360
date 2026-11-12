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

| Etapa | Qué es | Carpeta | Con qué lo corrimos | Estado |
|---|---|---|---|---|
| R0 | Preparar el equipo y revisar que todo funcione | `00_ARRANQUE` | `verificar_entorno.bat` | Listo |
| R1 | Base de datos de la operación | `01_OLTP` | `ejecutar_r1.bat` | Listo |
| R2 | Modelo para análisis | `02_DWH` | `ejecutar_r2.bat` | Listo |
| R3 | Pasar los datos al modelo de análisis (ETL) | `03_ETL` | `ejecutar_r3.bat` | Listo |
| R4 | Consultas SQL y archivos para el tablero | `04_KPI` | `ejecutar_r4.bat` | Listo |
| R5 | Indicadores (KPI) | `04_KPI` | `ejecutar_r5.bat` | Listo |
| R6 | Tablero en Power BI | `05_VISUALIZACION` | `Retail360.pbix` | Listo |
| R7 | Tablero web hecho con IA | `05_VISUALIZACION/web` | `ejecutar_r7.bat` | Listo |
| R8 | Hallazgos y decisiones | `06_INTERPRETACION` | `ejecutar_r8.bat` | Listo |
| R9 | Informe final | `07_INFORME` | - | Listo |

Todas las carpetas están dentro de `entregables_estudiante/`. En cada una dejamos un README con
lo que hay adentro y el resultado que nos dio.

**Lo primero que recomendamos leer:** el informe final, en `entregables_estudiante/07_INFORME/informe_final.md`.

Otros archivos útiles:

- `entregables_estudiante/PLAN_GATES.md` - el plan de etapas.
- `entregables_estudiante/DECISIONES.md` - lo que decidimos en el camino y por qué.
- `entregables_estudiante/IA/registro_ia.md` - cómo usamos la IA en cada etapa.

## Cómo lo corrimos nosotros

Todo lo corrimos en el computador de Miguel, con PostgreSQL 18 local, Python y Power BI
Desktop. Para correr cada etapa de una sola vez armamos un `.bat` por etapa: le dábamos doble clic, poníamos la contraseña de PostgreSQL y lo que salía quedaba
guardado en la carpeta `salidas` de esa etapa. Así cualquiera del grupo podía revisar qué dio
sin tener que volver a correrlo.

El orden que seguimos fue de R0 a R8, uno detrás del otro. Aprendimos que `ejecutar_r1.bat`
borra y vuelve a cargar los datos de la operación, así que cada vez que lo repetíamos
teníamos que volver a correr R2 y R3.

La página web quedó en `05_VISUALIZACION/web/tablero_retail360.html` y abre sin internet.
El tablero de Power BI está en `05_VISUALIZACION/Retail360.pbix`, conectado a `localhost`,
base `retail360`.

Si alguien repite los pasos, le deben salir los mismos números que pusimos en el informe.
El orden de los scripts originales del profesor está en `README_EJECUCION.txt`.

## Evidencias de nuestro trabajo

- **Salidas de cada etapa:** en cada carpeta hay un `salidas/salida_rX.txt` con lo que nos dio
  al correrlo, con fecha y hora. Por ejemplo, `00_ARRANQUE/evidencia_entorno.txt` dice
  `RESULTADO R0: OK` el 4 de noviembre de 2026.
- **Acuerdo de indicadores:** en `04_KPI/acuerdo_kpi.md` los 5 firmamos el catálogo el 4 de
  noviembre de 2026.
- **Tablero de Power BI:** el archivo `Retail360.pbix` con las 4 páginas.
- **Comparaciones:** `05_VISUALIZACION/equivalencia_r6.md` y `equivalencia_r7.md`, donde
  comparamos SQL, Power BI y la página web número por número.
- **Historial de GitHub:** cada etapa quedó en su propio commit, en orden.
- **Registro de IA:** `IA/registro_ia.md`, donde anotamos para qué la usamos y cómo lo
  comprobamos, como lo pide la guía.
