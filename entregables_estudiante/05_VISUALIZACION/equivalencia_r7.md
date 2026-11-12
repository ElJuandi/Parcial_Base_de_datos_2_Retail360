# Equivalencia SQL, Power BI y página web (R7)

Mismos 15 indicadores y mismos filtros en las tres herramientas.

- **Escenario A:** todo.
- **Escenario B:** Sucursal Pereira, septiembre de 2026.

Porcentajes multiplicados por 100.

| KPI | SQL (A) | Power BI (A) | HTML (A) | SQL (B) | Power BI (B) | HTML (B) | Conclusión |
|---|---|---|---|---|---|---|---|
| K01 Ventas netas | 77.065.123.983,86 | 77.065.123.983,86 | 77.065.123.983,86 | 946.766.660,41 | 946.766.660,41 | 946.766.660,41 | Igual |
| K02 Unidades netas | 90.095 | 90.095 | 90.095 | 1.128 | 1.128 | 1.128 | Igual |
| K03 Descuento % | 5,99 | 5,99 | 5,99 | 6,64 | 6,64 | 6,64 | Igual |
| K04 Devolución % | 0,81 | 0,81 | 0,81 | 1,31 | 1,31 | 1,31 | Igual |
| K05 Margen bruto | 24.544.503.983,86 | 24.544.503.983,86 | 24.544.503.983,86 | 289.928.660,41 | 289.928.660,41 | 289.928.660,41 | Igual |
| K06 Margen % | 31,85 | 31,85 | 31,85 | 30,62 | 30,62 | 30,62 | Igual |
| K07 Meta | 103.770.000.000,00 | 103.770.000.000,00 | 103.770.000.000,00 | 1.360.000.000,00 | 1.360.000.000,00 | 1.360.000.000,00 | Igual |
| K08 Cumplimiento % | 74,27 | 74,27 | 74,27 | 69,62 | 69,62 | 69,62 | Igual |
| K09 Meses con meta cumplida % | 20,28 | 20,28 | 20,28 | 40,00 | 40,00 | 40,00 | Igual |
| K10 Existencias | 122.341 | 122.341 | 122.341 | 23.598 | 23.598 | 23.598 | Igual |
| K11 Agotados | 7 | 7 | 7 | 2 | 2 | 2 | Igual |
| K12 Recaudo | 54.081.947.963,55 | 54.081.947.963,55 | 54.081.947.963,55 | 695.338.048,03 | 695.338.048,03 | 695.338.048,03 | Igual |
| K13 Saldo de cartera | 37.625.549.579,13 | 37.625.549.579,13 | 37.625.549.579,13 | 12.226.333.944,19 | 12.226.333.944,19 | 12.226.333.944,19 | Igual |
| K14 Cartera vencida % | 97,57 | 97,57 | 97,57 | 97,50 | 97,50 | 97,50 | Igual |
| K15 Facturación con IVA | 91.707.497.542,68 | 91.707.497.542,68 | 91.707.497.542,68 | 1.126.652.325,93 | 1.126.652.325,93 | 1.126.652.325,93 | Igual |

## Diferencias entre las herramientas (no de cifras, sino de alcance)

| Tema | Power BI | Página web |
|---|---|---|
| Recaudo por vendedor | Sí se puede (el modelo tiene la relación) | No: el archivo de recaudos no trae vendedor. La página lo avisa |
| Detalle por cliente | Sí (relación con la dimensión cliente) | No: los archivos están resumidos por mes, sin cliente, salvo la cartera |
| Datos | Se actualizan desde PostgreSQL con la contraseña | Quedan fijos en el archivo; para actualizarlos se corre `ejecutar_r7.bat` |
| Internet | No lo necesita una vez cargado | No lo necesita nunca |
