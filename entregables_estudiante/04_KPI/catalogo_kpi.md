# Catálogo de indicadores (KPI)

Este es el "contrato" de los indicadores: cómo se calcula cada uno, de dónde sale y cómo se
filtra. Power BI (R6) y la página web (R7) tienen que dar los mismos números que el SQL de
`kpi_referencia.sql`. Si una herramienta da otro valor, el error está en la herramienta, no en
el catálogo. Nada de esto se cambia sin que el grupo lo apruebe (`acuerdo_kpi.md`).

Reglas que valen para todos:

- Fecha de corte: 30 de septiembre de 2026. Periodo: octubre de 2024 a septiembre de 2026.
- Moneda: pesos colombianos (COP). Las ventas van **sin IVA**; recaudo y cartera van **con IVA**,
  porque son lo que el cliente paga.
- Los porcentajes se calculan dividiendo totales, nunca promediando porcentajes.
- Las notas crédito restan en el mes en que se hicieron (fecha del evento).
- Ningún hecho tiene vacíos en sus medidas. Si un filtro deja el denominador en 0, el
  indicador se muestra vacío (no 0 %).

## Preguntas por perspectiva

| Perspectiva | Pregunta | Indicadores |
|---|---|---|
| Comercial | ¿Cuánto vendemos, cuánto se devuelve y cuánto regalamos en descuento? | K01, K02, K03, K04 |
| Rentabilidad | ¿Cuánto nos queda después del costo de lo vendido? | K05, K06 |
| Productividad | ¿Los vendedores y las sucursales llegan a la meta? | K07, K08, K09 |
| Inventario | ¿Cuánto hay al corte y dónde falta? | K10, K11 |
| Financiera | ¿Cuánto facturamos, cuánto entra y cuánto nos deben? | K15, K12, K13, K14 |

## Los 15 indicadores

### K01. Ventas netas
- **Fórmula:** `SUM(fact_venta.venta_neta)`
- **Unidad:** COP sin IVA. **Grano del hecho:** línea de factura o de nota crédito.
- **Fecha:** del evento (factura o nota). **Devoluciones:** incluidas, restan.
- **Cuadre:** 77.065.123.983,86 = facturas 77.705.763.987,69 - notas 640.640.003,83 (R3).

### K02. Unidades netas
- **Fórmula:** `SUM(fact_venta.unidades)`
- **Unidad:** unidades. **Fecha:** del evento. **Devoluciones:** restan.
- **Cuadre:** 90.834 facturadas - 739 devueltas = 90.095.

### K03. Descuento efectivo %
- **Fórmula:** `SUM(descuento) / SUM(valor_bruto)`
- **Unidad:** %. **Fecha:** del evento. **Devoluciones:** incluidas con su signo.
- **Ojo:** es el descuento sobre el precio de la factura, no sobre el precio de lista.

### K04. Tasa de devolución %
- **Fórmula:** `-SUM(unidades de NOTA_CREDITO) / SUM(unidades de FACTURA)`
- **Unidad:** % de unidades. **Fecha:** del evento.
- **Denominador:** unidades facturadas, no netas (las netas ya tienen restada la devolución).
- **Ojo:** en un mes solo, la nota puede ser de una factura de otro mes. Se lee mejor en
  periodos largos.

### K05. Margen bruto
- **Fórmula:** `SUM(venta_neta - costo_venta)`
- **Unidad:** COP. **Fecha:** del evento. **Devoluciones:** restan venta y costo.
- **Ojo:** no es utilidad. No incluye arriendos, nómina, transporte ni comisiones.

### K06. Margen bruto %
- **Fórmula:** `K05 / K01`
- **Unidad:** %. **No es sumable:** se recalcula con cada filtro.

### K07. Meta de ventas
- **Fórmula:** `SUM(fact_meta.monto_meta)`
- **Unidad:** COP sin IVA. **Grano:** vendedor + sucursal + mes.
- **Filtros válidos:** solo mes, sucursal y vendedor. **No** se puede por categoría, producto
  ni cliente: la meta no tiene esos datos (ver reto C12).
- **Cuadre:** 103.770.000.000, 360 metas.

### K08. Cumplimiento de meta %
- **Fórmula:** `K01 / K07`, con la venta resumida primero al nivel de la meta.
- **Unidad:** %. **No es sumable.**
- **Ojo:** nunca se une la meta con las líneas de venta: se multiplica (prueba de R2).

### K09. Meses-vendedor con meta cumplida %
- **Fórmula:** `metas donde venta del vendedor ese mes >= meta / total de metas`
- **Unidad:** %. **Grano:** vendedor + sucursal + mes.
- **Para qué:** el K08 puede verse bien porque un mes muy bueno tapa varios malos. Este dice
  qué tan seguido se cumple.

### K10. Existencias al corte
- **Fórmula:** `SUM(cantidad_delta)` de los movimientos con fecha hasta el corte.
- **Unidad:** unidades. **Grano:** movimiento. **Filtros válidos:** bodega, sucursal, producto,
  categoría.
- **Ojo:** es una foto. No se filtra por mes ni se suman fotos de varias fechas.

### K11. Productos agotados en sucursales
- **Fórmula:** cantidad de pares bodega local + producto con existencia al corte `<= 0`.
- **Unidad:** cantidad. **Ojo:** no cuenta la bodega central, que no vende directo.

### K12. Recaudo
- **Fórmula:** `SUM(fact_recaudo.monto_recaudado)`
- **Unidad:** COP con IVA. **Fecha:** del pago, no de la factura.
- **Ojo:** es dinero que entró. No es lo que falta por cobrar.

### K13. Saldo de cartera al corte
- **Fórmula:** por factura, `total con IVA - notas - pagos` hasta el corte; luego se suma
  (vista `dwh.vw_cartera_corte`).
- **Unidad:** COP con IVA. **Filtros válidos:** sucursal, vendedor, cliente.
- **Ojo:** no se calcula restando flujos de meses (reto C10).

### K14. Cartera vencida %
- **Fórmula:** `SUM(saldo de facturas con vencimiento antes del corte) / K13`
- **Unidad:** %. **No es sumable.**

### K15. Facturación con IVA
- **Fórmula:** `SUM(fact_venta.valor_facturado_con_impuesto)`
- **Unidad:** COP con IVA. **Fecha:** del evento. **Devoluciones:** restan.
- **Para qué:** ponerla al lado del recaudo (K12), que también va con IVA. Compararlo con las
  ventas netas sin IVA sería mezclar peras con manzanas.
- **Cuadre:** 91.707.497.542,68.

## Matriz indicador - hecho - filtros

"Sí" = el filtro se puede usar. "No" = el tablero no debe permitirlo para ese indicador.

| KPI | Hecho o vista | Fecha | Sucursal | Vendedor | Categoría / producto | Cliente | Bodega |
|---|---|---|---|---|---|---|---|
| K01 a K06, K15 | `fact_venta` | Sí (evento) | Sí | Sí | Sí | Sí | No |
| K07 a K09 | `fact_meta` + venta resumida | Sí (mes) | Sí | Sí | **No** | **No** | No |
| K10, K11 | `fact_movimiento_inventario` / `vw_stock_corte` | Solo el corte | Sí (por su bodega) | No | Sí | No | Sí |
| K12 | `fact_recaudo` | Sí (pago) | Sí | Sí | No | Sí | No |
| K13, K14 | `vw_cartera_corte` | Solo el corte | Sí | Sí | No | Sí | No |

## Lo que NO vamos a mostrar

El caso no trae estos datos, así que no los inventamos:

- **Utilidad neta:** faltan arriendos, nómina, transporte y demás gastos.
- **Rotación de inventario valorizada:** necesita el valor del inventario mes a mes con costos
  consistentes; solo tenemos unidades y un costo estándar fijo.
- **Margen por vendedor después de comisiones:** no hay datos de comisiones.
- **Meta por categoría:** la meta no tiene categoría.

## Valores oficiales (SQL)

Salen de `kpi_referencia.sql`. Escenario A = toda la empresa y todo el periodo. Escenario
B = Sucursal Pereira en septiembre de 2026 (existencias y cartera solo filtran la sucursal).

| KPI | A: todo | B: Pereira, sep-2026 |
|---|---|---|
| K01 Ventas netas | 77.065.123.983,86 | 946.766.660,41 |
| K02 Unidades netas | 90.095 | 1.128 |
| K03 Descuento efectivo | 5,99 % | 6,64 % |
| K04 Devolución | 0,81 % | 1,31 % |
| K05 Margen bruto | 24.544.503.983,86 | 289.928.660,41 |
| K06 Margen bruto | 31,85 % | 30,62 % |
| K07 Meta | 103.770.000.000,00 | 1.360.000.000,00 |
| K08 Cumplimiento | 74,27 % | 69,62 % |
| K09 Meses con meta cumplida | 20,28 % | 40,00 % |
| K10 Existencias | 122.341 | 23.598 |
| K11 Agotados en sucursales | 7 | 2 |
| K12 Recaudo | 54.081.947.963,55 | 695.338.048,03 |
| K13 Saldo de cartera | 37.625.549.579,13 | 12.226.333.944,19 |
| K14 Cartera vencida | 97,57 % | 97,50 % |
| K15 Facturación con IVA | 91.707.497.542,68 | 1.126.652.325,93 |
