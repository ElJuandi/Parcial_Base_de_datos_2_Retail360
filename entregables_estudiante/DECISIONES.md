# Decisiones del grupo

Aquí anotamos lo que vamos decidiendo y por qué.

1. **Nos guiamos por la guía del profesor y sus scripts.** Las infografías del curso nos sirven para
   el orden del trabajo y para algunas columnas extra, pero no inventamos datos que no existen
   (por ejemplo, el "cargo" del vendedor no viene en los datos).
2. **No tocamos los archivos del profesor.** Lo nuestro va en `entregables_estudiante/`.
3. **Hacemos nuestro propio ETL.** El archivo `sql/05_etl_referencia.sql` lo usamos solo para
   comparar al final.
4. **Los 12 retos SQL los hacemos después del ETL**, porque necesitan el modelo de análisis ya cargado.
5. **Somos 5 integrantes.** La guía habla de grupos de 3, pero trabajamos como el grupo del semestre.
6. **La base de datos es local** (PostgreSQL instalado en el computador), no en la nube.
7. **El computador principal es el de Miguel.** Ahí corren la base, los scripts y Power BI.
   Tiene PostgreSQL 18; la guía pide la 17, pero los scripts funcionan igual en versiones nuevas.
8. **La página web final funciona sin internet**, como pide la guía.

9. **Comparamos nuestro ETL con el del profesor** fila por fila al final de R3. Quedaron iguales.
10. **Las devoluciones entran como ventas negativas** con su propia fecha. No borran la venta original.
11. **Al final fueron 15 indicadores y no 12.** Uno de los que agregamos es K15 (facturación con
    IVA): sin él, el recaudo, que va con IVA, se habría comparado con ventas sin IVA.
12. **Cambiamos tres relaciones en Power BI** para que los filtros de vendedor y la cartera
    funcionaran. El detalle está en `05_VISUALIZACION/modelo_powerbi.md`.
13. **Power BI quedó con la cuenta de la universidad de Miguel**, porque así se le guarda el archivo.
14. **Para la página web sacamos 2 archivos más** (cartera al corte y unidades por mes), porque
    los 4 del profesor no alcanzaban para calcular todos los indicadores.
15. **En los hallazgos separamos lo que vimos de lo que creemos.** Lo que no se puede probar con
    los datos lo dejamos como hipótesis.

## Cosas que notamos del paquete

- La fecha de corte de los análisis es el 30 de septiembre de 2026.
- Los clientes "persona" no tienen días de crédito, por eso casi toda la cartera aparece como
  vencida. Lo explicamos en el hallazgo 4 (R8).
- El modelo de la infografía no trae las notas crédito ni la tabla de sucursales; el paquete sí,
  así que las incluimos.
