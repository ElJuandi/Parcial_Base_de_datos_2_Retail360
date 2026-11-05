# Los 12 retos SQL explicados

Las consultas están en `retos_r4.sql` y lo que salió al correrlas está en `salidas/salida_r4.txt`.
Fecha de corte: 30 de septiembre de 2026. Los montos van sin IVA, menos en C06 y C10, que van
con IVA porque hablan de lo que el cliente tiene que pagar.

## C01. Venta neta por mes

**Cómo:** sumamos `venta_neta` por mes según la fecha de cada evento. Las notas crédito restan
en el mes en que se hicieron, no en el de la factura original.

**Resultado:** en 24 meses la venta neta fue de 77.065 millones. El mes más bajo fue febrero de
2026 (2.871 millones) y el más alto octubre de 2025 (3.737 millones). Las devoluciones restan
entre 8 y 54 millones al mes, y septiembre de 2026 tiene la más alta.

**Qué significa:** las ventas suben y bajan, pero no tienen una tendencia clara de crecimiento.
Marzo es un mes fuerte en los dos años (sube 19 % y 23 % frente a febrero).

## C02. Top 10 clientes por venta neta y margen

**Cómo:** venta neta y margen bruto por cliente, con dos puestos: uno por venta y otro por
margen.

**Resultado:** el mejor cliente compró 145 millones. 9 de los 10 primeros son personas. El
puesto por margen casi siempre es igual al de venta. Los que más bajan son el cliente 0425
(sexto en venta, noveno en margen, con 29,8 %) y el 1105 (octavo en venta, undécimo en margen).

**Qué excluye el margen bruto:** solo resta el costo de lo vendido. No incluye arriendos,
nómina, transporte, comisiones ni impuestos. Por eso no es la utilidad de la empresa.

## C03. Metas contra ventas sin duplicar

**Cómo:** primero resumimos las ventas al mismo nivel de la meta (vendedor, sucursal y mes) y
solo después unimos las dos tablas. Así cada meta aparece una vez.

**Resultado:** 360 filas (15 vendedores por 24 meses), meta total de 103.770 millones y
cumplimiento de 74,3 %. Ningún vendedor llega a 100 % en el periodo completo. La mejor es Olga
López con 82,7 % y el último es Jorge Ríos con 65,4 %. De los 360 meses, solo en 73 se cumplió
la meta.

**Nota:** en R2 dio 74,9 % porque esa prueba usaba solo facturas. Con las notas crédito
restando, el cumplimiento correcto es 74,3 %.

## C04. Existencias al corte

**Cómo:** el saldo de cada producto en cada bodega es la suma de todos sus movimientos hasta el
30 de septiembre de 2026. No sumamos fotos de varias fechas, porque eso cuenta las mismas
unidades varias veces.

**Resultado:** 122.341 unidades (igual que en R1). La bodega central tiene 46.526 y las locales
entre 23.598 y 26.282. Hay 7 productos en cero en las bodegas locales (4 en Medellín) y ninguno
en negativo.

## C05. Devoluciones por producto

**Cómo:** tasa = unidades devueltas / unidades facturadas. El denominador es lo facturado y no
la venta neta, porque la venta neta ya tiene restadas las devoluciones y la tasa saldría
inflada. Solo mostramos productos con 50 unidades vendidas o más.

**Resultado:** la empresa devuelve el 0,81 % de las unidades. Por producto, la tasa más alta es
4,17 % (Mouse modelo 256). Por categoría va de 0,51 % (Impresoras) a 0,97 % (Monitores y
Auriculares).

**Qué significa:** las devoluciones son pocas y no explican por qué el margen es bajo.

## C06. Facturas vencidas y saldo al corte

**Cómo:** usamos la vista de cartera del script 10, que calcula cada factura por aparte: total
menos notas menos pagos.

**Resultado:** de 92.470 millones facturados (con IVA) quedan 37.626 millones por cobrar, y
36.712 millones de esos ya están vencidos (97,6 %). 6.543 facturas están vencidas y el 71,7 %
del saldo lleva más de 180 días.

**Qué significa:** las personas pagan de contado (0 días de plazo), así que todo lo que no
pagan queda vencido desde el mismo día. Ellas deben 27.860 millones, casi tres veces lo que
deben las empresas.

## C07. Cumplen la meta pero con margen bajo

**Cómo:** por mes, buscamos vendedores con cumplimiento de 100 % o más y margen 2 puntos o más
por debajo del margen de la empresa en ese mismo mes.

**Resultado:** salen 5 meses y siempre son los mismos dos vendedores: Eliana Soto (vendedora 5)
y Jorge Ríos (vendedor 10). En esos meses cumplieron hasta el 163 %, pero con un margen de
27 % a 28 % contra 32 % de la empresa. En todo el periodo dan cerca de 12 % de descuento,
cuando los demás dan alrededor de 5 %.

**Qué significa:** estos dos alcanzan la meta a punta de descuentos. Si la meta solo mide
ventas, premia vender barato.

## C08. Pedidos pendientes por falta de stock

**Cómo:** para cada línea de los pedidos `PENDIENTE_STOCK` calculamos la existencia en la
bodega de la sucursal y en la central el día del pedido.

**Resultado:** 839 pedidos (3.336 líneas). En 740 líneas la bodega local no alcanzaba, y en
**todas** ellas la central sí tenía. No hubo ningún caso sin existencia en las dos bodegas.

**Ojo con las fechas:** no tienen hora. En 34 de esas 740 líneas hubo un movimiento ese mismo
día en esa bodega y no sabemos si pasó antes o después del pedido.

**Qué significa:** el problema no es de compras sino de mover el inventario a tiempo desde la
central a las sucursales.

## C09. Categorías con más descuento

**Cómo:** descuento efectivo = pesos descontados / valor bruto.

**Resultado:** todas están entre 5,6 % y 6,2 %. Accesorios tiene el mayor (6,20 %) y
Componentes el menor (5,60 %).

**Qué significa:** el descuento no cambia mucho entre categorías. Lo que sí se destaca es Redes,
con un margen de 25,8 % frente a cerca de 32 % del resto, aunque su descuento es normal. Su
problema parece ser el costo o el precio, no el descuento.

## C10. Facturación contra recaudo

**Cómo:** facturado (con IVA), notas y recaudo de cada mes, cada uno con su propia fecha.

**Resultado:** cada mes se recauda entre el 46 % y el 68 % de lo que se factura en ese mismo
mes. La resta total, facturado menos notas menos recaudado, da 37.626 millones, igual al saldo
de C06.

**Por qué no basta con restar flujos:** la resta da el saldo total, pero no dice qué facturas
están vencidas ni hace cuánto. Un pago de octubre puede ser de una factura de enero. Lo vencido
(36.712 millones) solo se ve factura por factura.

## C11. Concentración de clientes (Pareto)

**Cómo:** ordenamos los clientes de mayor a menor venta neta y fuimos sumando.

**Resultado:** se necesitan 956 de 1.498 clientes (63,8 %) para llegar al 80 % de la venta. El
20 % de clientes que más compra solo hace el 33,3 %.

**Qué significa:** no hay dependencia de pocos clientes. Perder un cliente grande no sería
grave.

## C12. Una gráfica errada de metas por categoría

**Cómo:** unimos la vista de metas con la de ventas por categoría, como pasaría si alguien las
relaciona directamente en Power BI.

**Resultado:** la meta pasa de 103.770 millones a 1,24 billones, unas 12 veces más, porque cada
meta se repite una vez por cada categoría que vendió ese vendedor ese mes. En la gráfica cada
categoría tendría casi toda la meta de la empresa.

**Qué significa:** la meta no tiene categoría. En los tableros solo se puede comparar por
vendedor, sucursal y mes. Repartirla por categoría sería un supuesto nuestro, no un dato.
