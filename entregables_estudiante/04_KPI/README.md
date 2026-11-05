# R4 y R5 - Consultas e indicadores

Aquí van los 12 retos SQL, los archivos exportados para el tablero web y, en R5, la lista de
indicadores con sus fórmulas.

## R4 - Consultas

### Archivos

- `retos_r4.sql` - las consultas de los 12 retos del script 11 del profesor.
- `retos_explicados.md` - cómo resolvimos cada reto, qué salió y qué significa.
- `exportes.md` - qué trae cada uno de los 4 CSV y cómo no se deben mezclar.
- `validar_exportes.sql` - revisa que las vistas exportadas cuadren con el modelo.
- `ejecutar_r4.bat` - corre todo con doble clic.
- `salidas/salida_r4.txt` - lo que salió al correrlo.

Los 4 CSV quedan en la carpeta `export/` de la raíz.

### Cómo correrlo

Primero deben estar hechas R1, R2 y R3. Luego doble clic a `ejecutar_r4.bat` y escribir la
contraseña de PostgreSQL. Corre los scripts 07, 10 y 08 del profesor, después nuestros retos y
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
