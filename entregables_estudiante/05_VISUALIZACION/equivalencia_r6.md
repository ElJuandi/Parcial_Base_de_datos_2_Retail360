# Equivalencia SQL contra Power BI (R6)

La guía pide comparar mínimo 7 indicadores con los mismos filtros. Comparamos los 15.

**Cómo lo hicimos:** en la vista de consultas DAX de Power BI corrimos `powerbi/equivalencia_r6.dax`,
que calcula cada medida en los dos escenarios del catálogo. Lo comparamos con lo que dio
`04_KPI/kpi_referencia.sql` en R5. Los porcentajes están multiplicados por 100 y todo va
redondeado a 2 decimales.

- **Escenario A:** toda la empresa, todo el periodo.
- **Escenario B:** Sucursal Pereira y septiembre de 2026. Existencias y cartera solo filtran la
  sucursal, porque son fotos al corte.

| KPI | A: SQL | A: Power BI | B: SQL | B: Power BI | ¿Igual? |
|---|---|---|---|---|---|
| K01 Ventas netas | 77.065.123.983,86 | 77.065.123.983,86 | 946.766.660,41 | 946.766.660,41 | Sí |
| K02 Unidades netas | 90.095 | 90.095 | 1.128 | 1.128 | Sí |
| K03 Descuento efectivo % | 5,99 | 5,99 | 6,64 | 6,64 | Sí |
| K04 Devolución % | 0,81 | 0,81 | 1,31 | 1,31 | Sí |
| K05 Margen bruto | 24.544.503.983,86 | 24.544.503.983,86 | 289.928.660,41 | 289.928.660,41 | Sí |
| K06 Margen bruto % | 31,85 | 31,85 | 30,62 | 30,62 | Sí |
| K07 Meta | 103.770.000.000,00 | 103.770.000.000,00 | 1.360.000.000,00 | 1.360.000.000,00 | Sí |
| K08 Cumplimiento % | 74,27 | 74,27 | 69,62 | 69,62 | Sí |
| K09 Meses con meta cumplida % | 20,28 | 20,28 | 40,00 | 40,00 | Sí |
| K10 Existencias al corte | 122.341 | 122.341 | 23.598 | 23.598 | Sí |
| K11 Agotados en sucursales | 7 | 7 | 2 | 2 | Sí |
| K12 Recaudo | 54.081.947.963,55 | 54.081.947.963,55 | 695.338.048,03 | 695.338.048,03 | Sí |
| K13 Saldo de cartera | 37.625.549.579,13 | 37.625.549.579,13 | 12.226.333.944,19 | 12.226.333.944,19 | Sí |
| K14 Cartera vencida % | 97,57 | 97,57 | 97,50 | 97,50 | Sí |
| K15 Facturación con IVA | 91.707.497.542,68 | 91.707.497.542,68 | 1.126.652.325,93 | 1.126.652.325,93 | Sí |

**Resultado:** 15 de 15 iguales en los dos escenarios.

**Prueba en el tablero:** además, en la página 3 pusimos los filtros a mano (mes 2026-09 y
Sucursal Pereira). Las tarjetas mostraron meta 1,36 mil millones, ventas 946,77 millones,
cumplimiento 69,62 % y meses con meta cumplida 40,00 %, igual que en SQL.
