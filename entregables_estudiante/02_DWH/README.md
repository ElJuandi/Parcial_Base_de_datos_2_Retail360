# R2 - Modelo para análisis

Aquí diseñamos el modelo en constelación: 4 tablas de hechos y 6 dimensiones.

## Archivos

- `preguntas_negocio.md` - las 10 preguntas que queremos responder.
- `modelo_dimensional.md` - las tablas de hechos, la matriz bus, qué se puede sumar, las dimensiones y la propuesta para guardar historia del vendedor.
- `diagrama_estrella.md` y `diagrama_estrella.png` - el diagrama del modelo.
- `ajustes_dwh_grupo.sql` - las columnas que agregamos al modelo del profesor.
- `demo_meta_duplicada.sql` - la prueba de por qué la meta no se puede pegar a cada venta.
- `consultas_r2.sql` - revisa las tablas y relaciones que quedaron creadas.
- `ejecutar_r2.bat` - corre todo con doble clic.
- `salidas/salida_r2.txt` - lo que salió al correrlo.

## Cuándo damos R2 por terminada

- El modelo queda creado (script 04 del profesor + nuestros ajustes) y coincide con el diagrama.
- La prueba de la meta muestra el error y la forma correcta.

## Resultado

Lo corrimos el 4 de noviembre de 2026 en el computador de Miguel, sin errores. Quedaron las
10 tablas del modelo (6 dimensiones y 4 hechos) más la bitácora, con las 17 relaciones del
diagrama. La prueba de la meta dio: meta real de 103.770 millones, meta inflada de 8,7 billones
si se pega a cada venta, y un cumplimiento de 74,9 % calculado de la forma correcta.
Las tablas quedan vacías; se llenan en R3.
