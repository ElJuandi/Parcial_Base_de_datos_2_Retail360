# R6 y R7 - Tableros

Aquí va el tablero de Power BI (R6) y, en R7, la página web que funciona sin internet.

## R6 - Power BI

### Archivos

- `Retail360.pbix` - el tablero, con 4 páginas.
- `modelo_powerbi.md` - qué tablas trae, cómo quedaron las relaciones, las medidas y las páginas.
- `powerbi/medidas_y_relaciones.tmdl` - el script con las 15 medidas y las relaciones de la cartera.
- `powerbi/equivalencia_r6.dax` - la consulta DAX que calcula los 15 indicadores en los dos escenarios.
- `equivalencia_r6.md` - la comparación con SQL.

### Cómo lo dejamos

El archivo `Retail360.pbix` quedó con los datos guardados, así que se ve aunque no esté
conectado a la base. Cuando le dimos Actualizar (Inicio → Actualizar), Power BI nos pidió la
contraseña de PostgreSQL del usuario `postgres`. Para eso ya teníamos corridas R1 a R4.

### Cuándo damos R6 por terminada

- Las 4 páginas del boceto de R5 están armadas.
- Mínimo 7 indicadores dan igual en Power BI y en SQL con los mismos filtros.

### Resultado

Lo armamos el 11 de noviembre de 2026 en el computador de Miguel. Los 15 indicadores dan
exactamente lo mismo que SQL en los dos escenarios (ver `equivalencia_r6.md`).

## R7 - Página web sin internet

### Archivos

- `web/tablero_retail360.html` - la página. Abre con doble clic y no necesita internet.
- `web/plantilla_tablero.html` - el diseño de la página, sin datos.
- `web/generar_tablero.py` - mete los datos de `export/` dentro de la plantilla y escribe la página.
- `web/exportar_extra.psql` - saca dos archivos más (`cartera_corte.csv` y `unidades_mensuales.csv`),
  que hacen falta para la cartera y la devolución.
- `web/ejecutar_r7.bat` - con el que exportamos los CSV y armamos la página de una vez.
- `web/prompt_ia.md` - qué le pedimos a la IA, el mapeo de indicadores y las decisiones.
- `equivalencia_r7.md` - la comparación SQL, Power BI y página web.
- `web/salidas/salida_r7.txt` - lo que salió al correrlo.

### Cómo lo corrimos

Corrimos `web/ejecutar_r7.bat` con la contraseña de PostgreSQL. Después abrimos
`web/tablero_retail360.html` y revisamos la pestaña **Validación**: nos dio 15 de 15 iguales.

### Cuándo damos R7 por terminada

- La página abre sin internet, con 4 tableros, filtros, fecha de corte y definiciones.
- Da las mismas cifras que SQL y Power BI con los mismos filtros.
