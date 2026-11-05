# Casos de prueba con datos pequeños

Antes de armar los tableros hicimos un ejemplo diminuto, calculamos cada indicador a mano y
después comprobamos con `casos_prueba_kpi.sql` que las fórmulas del catálogo dan lo mismo.
También incluimos las formas equivocadas más comunes para ver cuánto se desvían.

## Los datos del ejemplo

**Ventas** (enero y febrero, dos vendedores):

| Línea | Tipo | Mes | Vendedor | Categoría | Unidades | Bruto | Descuento | Neto | Costo | IVA 19 % |
|---|---|---|---|---|---|---|---|---|---|---|
| F1 | Factura | Enero | Ana | Portátiles | 2 | 1.000 | 100 | 900 | 600 | 171 |
| F2 | Factura | Enero | Ana | Mouse | 1 | 500 | 0 | 500 | 400 | 95 |
| F3 | Factura | Enero | Beto | Portátiles | 4 | 2.000 | 400 | 1.600 | 1.200 | 304 |
| N1 | Nota crédito | Febrero | Ana | Portátiles | -1 | -500 | -50 | -450 | -300 | -85,5 |

N1 es la devolución de 1 portátil de F1, hecha en febrero.

**Metas:** Ana enero 2.000, Beto enero 1.500, Ana febrero 1.000, Beto febrero 1.000.

**Inventario** (una bodega local, corte = día 59): producto P entra 10 el día 1, salen 3 el día 15
y 7 el día 40. Producto Q entra 5 el día 1 y no se mueve.

**Cartera** (corte = día 59): factura FA por 1.000 con nota de 100, vence el día 10, pagan 400
el día 20. Factura FB por 2.000, vence el día 70, pagan 500 el día 45.

## Cálculo a mano

| KPI | Cuenta | Resultado |
|---|---|---|
| K01 Ventas netas | 900 + 500 + 1.600 - 450 | **2.550** (enero 3.000, febrero -450) |
| K02 Unidades netas | 2 + 1 + 4 - 1 | **6** |
| K03 Descuento efectivo | (100 + 0 + 400 - 50) / (1.000 + 500 + 2.000 - 500) = 450 / 3.000 | **15,00 %** |
| K04 Devolución | 1 / 7 unidades facturadas | **14,29 %** |
| K05 Margen bruto | 2.550 - 1.900 | **650** |
| K06 Margen bruto % | 650 / 2.550 | **25,49 %** |
| K07 Meta | 2.000 + 1.500 + 1.000 + 1.000 | **5.500** |
| K08 Cumplimiento | 2.550 / 5.500 | **46,36 %** |
| K09 Meses con meta cumplida | Solo Beto en enero (1.600 >= 1.500): 1 de 4 | **25,00 %** |
| K10 Existencias al corte | P: 10 - 3 - 7 = 0; Q: 5 | **5** |
| K11 Agotados | Solo P | **1** |
| K12 Recaudo | 400 + 500 | **900** |
| K13 Saldo de cartera | FA: 1.000 - 100 - 400 = 500; FB: 2.000 - 500 = 1.500 | **2.000** |
| K14 Cartera vencida | Solo FA está vencida: 500 / 2.000 | **25,00 %** |
| K15 Facturación con IVA | 2.550 + (171 + 95 + 304 - 85,5) | **3.034,50** |

## Las trampas

| Forma equivocada | Da | Correcto | Por qué está mal |
|---|---|---|---|
| Margen %: promediar el % de cada línea | 27,92 % | 25,49 % | Una línea pequeña pesa igual que una grande |
| Devolución: dividir por unidades netas | 16,67 % | 14,29 % | El denominador ya tiene restada la devolución |
| Meta: pegarla a cada línea de venta | 6.500 | 5.500 | La meta de Ana en enero se cuenta 2 veces porque tiene 2 líneas (+2.000) y la de Beto en febrero desaparece porque no vendió (-1.000) |
| Inventario: sumar la foto de enero y la de febrero | 17 unidades | 5 | Se cuentan las mismas unidades dos veces |

## Resultado

`casos_prueba_kpi.sql` termina con `CASOS DE PRUEBA OK` si los 15 indicadores dan lo que
está en la tabla. Si alguno no coincide, se detiene y dice cuál.
