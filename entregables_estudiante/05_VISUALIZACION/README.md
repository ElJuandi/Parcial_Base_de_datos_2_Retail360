# R6 y R7 - Tableros

Aquí va el tablero de Power BI (R6) y, en R7, la página web que funciona sin internet.

## R6 - Power BI

### Archivos

- `Retail360.pbix` - el tablero, con 4 páginas.
- `modelo_powerbi.md` - qué tablas trae, cómo quedaron las relaciones, las medidas y las páginas.
- `powerbi/medidas_y_relaciones.tmdl` - el script con las 15 medidas y las relaciones de la cartera.
- `powerbi/equivalencia_r6.dax` - la consulta DAX que calcula los 15 indicadores en los dos escenarios.
- `equivalencia_r6.md` - la comparación con SQL.

### Cómo abrirlo

Abrir `Retail360.pbix` con Power BI Desktop. Trae los datos guardados, así que se ve sin
conectarse. Para actualizar los datos (Inicio → Actualizar), Power BI pide la contraseña de
PostgreSQL del usuario `postgres`. Antes de eso hay que haber corrido R1 a R4.

### Cuándo damos R6 por terminada

- Las 4 páginas del boceto de R5 están armadas.
- Mínimo 7 indicadores dan igual en Power BI y en SQL con los mismos filtros.

### Resultado

Lo armamos el 11 de noviembre de 2026 en el computador de Miguel. Los 15 indicadores dan
exactamente lo mismo que SQL en los dos escenarios (ver `equivalencia_r6.md`).
