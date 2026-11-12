# R4 y R5 - Consultas e indicadores

Aquí van los 12 retos SQL, los archivos exportados para el tablero web y, en R5, la lista de
indicadores con sus fórmulas.

## R4 - Consultas

### Archivos

- `retos_r4.sql` - las consultas de los 12 retos del script 11 del profesor.
- `retos_explicados.md` - cómo resolvimos cada reto, qué salió y qué significa.
- `exportes.md` - qué trae cada uno de los 4 CSV y cómo no se deben mezclar.
- `validar_exportes.sql` - revisa que las vistas exportadas cuadren con el modelo.
- `ejecutar_r4.bat` - el archivo con el que corrimos todo de una vez.
- `salidas/salida_r4.txt` - lo que salió al correrlo.

Los 4 CSV quedan en la carpeta `export/` de la raíz.

### Cómo lo corrimos

Con R1, R2 y R3 ya hechas, corrimos `ejecutar_r4.bat` con la contraseña de PostgreSQL. Corre los scripts 07, 10 y 08 del profesor, después nuestros retos y
al final la revisión de los archivos.

### Cuándo damos R4 por terminada

- Mínimo 10 retos resueltos y explicados (hicimos los 12, incluidos los 2 bonus).
- Los 4 CSV generados, con las mismas filas y totales que el modelo.

### Resultado

Lo corrimos el 4 de noviembre de 2026 en el computador de Miguel, sin errores.

- Resolvimos y explicamos los 12 retos.
- Se generaron los 4 CSV en `export/`: 4.316 filas de ventas, 360 de metas, 7.583 de recaudos
  y 1.600 de existencias.
- Cada archivo cuadra con el modelo: venta neta 77.065.123.983,86, meta 103.770.000.000,00,
  recaudo 54.081.947.963,55 y 122.341 unidades al corte.

## R5 - Indicadores

### Archivos

- `catalogo_kpi.md` - los 15 indicadores: fórmula, unidad, fecha, filtros, devoluciones, la
  matriz indicador-hecho-filtro, lo que no vamos a mostrar y los valores oficiales.
- `kpi_referencia.sql` - calcula en SQL el valor oficial de cada indicador en dos escenarios
  (A: todo; B: Pereira en septiembre de 2026). Contra esto se comparan Power BI y la página web.
- `casos_prueba_kpi.md` y `casos_prueba_kpi.sql` - un ejemplo pequeño calculado a mano y la
  prueba de que las fórmulas dan lo mismo, más las formas equivocadas.
- `wireframes.md` y la carpeta `wireframes/` - los bocetos de las 4 páginas y por qué elegimos
  cada gráfica.
- `acuerdo_kpi.md` - donde cada integrante aprueba el catálogo.
- `ejecutar_r5.bat` - con el que corrimos las pruebas y los valores oficiales.
- `salidas/salida_r5.txt` - lo que salió al correrlo.

### Cuándo damos R5 por terminada

- Los casos de prueba dan `CASOS DE PRUEBA OK`.
- Los 5 integrantes aprueban el catálogo en `acuerdo_kpi.md`. Hasta entonces no se abre Power BI.

### Resultado

Lo corrimos el 4 de noviembre de 2026 en el computador de Miguel, sin errores. Los casos de
prueba dieron `CASOS DE PRUEBA OK` y los valores oficiales coinciden con los del catálogo.
Ese mismo día los 5 integrantes revisamos y aprobamos el catálogo (`acuerdo_kpi.md`).
