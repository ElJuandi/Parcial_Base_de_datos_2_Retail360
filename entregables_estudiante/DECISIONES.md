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

## Cosas que notamos del paquete

- La fecha de corte de los análisis es el 30 de septiembre de 2026.
- Los clientes "persona" no tienen días de crédito, por eso casi toda la cartera aparece como
  vencida. Esto hay que explicarlo cuando lleguemos a los hallazgos.
- El modelo de la infografía no trae las notas crédito ni la tabla de sucursales; el paquete sí,
  así que las incluimos.
