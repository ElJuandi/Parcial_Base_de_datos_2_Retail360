# Hallazgos y decisiones

La pregunta del caso era por qué la tienda vende más pero gana menos, se queda sin productos y
no logra cobrar lo que factura. Esto es lo que encontramos en los datos (octubre de 2024 a
septiembre de 2026, corte al 30/09/2026).

Para no mezclar las cosas, en cada hallazgo separamos lo que **vimos** (un hecho que se puede
comprobar con una consulta), lo que **creemos** que lo explica (una hipótesis) y lo que **no
sabemos**. Los datos son sintéticos y no traen gastos como arriendo o nómina, así que no
hablamos de utilidad, solo de margen bruto.

---

## Hallazgo 1. Nadie está llegando a la meta

**Lo que vimos.** Entre todos se vendió el 74,3 % de la meta. De los 15 vendedores, ninguno llegó
al 100 % en el periodo completo. De 360 metas mensuales (15 vendedores por 24 meses), solo se
cumplieron 73, o sea 1 de cada 5.

**De dónde sale.** `consultas_r8.sql` (H1) y el reto C03. En Power BI, página 3 "Vendedores y
metas". En la página web, pestaña 3.

**Lo que creemos.** Las metas pueden estar muy por encima de lo que la tienda realmente vende:
la venta mensual se mueve alrededor de 3.200 millones y la meta de la empresa anda cerca de
4.300 millones.

**Lo que no sabemos.** No sabemos cómo se pusieron las metas. Puede que las metas estén bien y
el problema sea de ventas, o al revés.

---

## Hallazgo 2. Dos vendedores cumplen regalando margen

**Lo que vimos.** Eliana Soto y Jorge Ríos dan en promedio 12 % de descuento; los otros 13
vendedores dan 5 %. Por eso su margen bruto es de 27 %, contra 32,5 % del resto. Cuando alguien
cumple la meta con un margen bajo, siempre es uno de estos dos (5 meses en total).

**De dónde sale.** `consultas_r8.sql` (H2) y el reto C07. En Power BI, la dispersión de
descuento contra margen (página 1) y la tabla por vendedor (página 3). En la página web, la
tabla "Descuento y margen por vendedor".

**Lo que creemos.** La meta solo mide cuánto se vende, no cuánto se gana. Así, dar descuento es
una forma fácil de llegar.

**Lo que no sabemos.** Puede que atiendan clientes que piden más descuento, o que tengan
permiso para darlo. Si hubieran vendido con el margen del resto, la tienda habría ganado unos
500 millones más de margen bruto. Esa cifra es un cálculo nuestro, no un dato.

---

## Hallazgo 3. Los productos sí están, pero en la bodega equivocada

**Lo que vimos.** Hubo 839 pedidos frenados por falta de stock. En las 740 líneas donde la bodega
de la sucursal no alcanzaba, la bodega central sí tenía las unidades, en todas sin excepción.
La central guarda el 38 % de todo el inventario.

**De dónde sale.** `consultas_r8.sql` (H3) y el reto C08, con datos de la operación. En Power BI
y en la página web está en la página 2, "Inventario al corte".

**Lo que creemos.** Falta mover inventario de la central a las sucursales a tiempo. No es un
problema de comprar más.

**Lo que no sabemos.** Las fechas no tienen hora. En 34 de esas 740 líneas hubo un movimiento el
mismo día y no sabemos si llegó antes o después del pedido.

---

## Hallazgo 4. Casi todo lo que se debe ya está vencido

**Lo que vimos.** De lo facturado solo entró el 59 %. Quedan 37.626 millones por cobrar, y el
97,6 % de eso ya está vencido. Más de la mitad del total (71,7 %) lleva más de 180 días. Las
personas deben 27.860 millones, casi tres veces lo que deben las empresas.

**De dónde sale.** `consultas_r8.sql` (H4) y los retos C06 y C10. En Power BI, página 4. En la
página web, pestaña 4.

**Lo que creemos.** A las personas se les factura de contado (0 días). Si no pagan en el momento,
la factura queda vencida desde el primer día y nadie la persigue.

**Lo que no sabemos.** No hay datos de gestión de cobro (llamadas, acuerdos de pago), así que no
podemos decir si se intentó cobrar.

---

## Hallazgo 5. Redes es la categoría que menos deja

**Lo que vimos.** Redes tiene un margen bruto de 25,8 %; las demás categorías están entre 30 % y
34 %. Y no es por descuentos, porque Redes da un descuento normal (6,2 %). Lo que pasa es que su
costo se come el 69,6 % del precio, el más alto de todas.

**De dónde sale.** `consultas_r8.sql` (H5) y el reto C09. En Power BI, "Ventas por categoría"
(página 1). En la página web, la tabla por categoría de la pestaña 1.

**Lo que creemos.** El precio de Redes está bajo para lo que cuesta, o el proveedor la vende cara.

**Lo que no sabemos.** No tenemos precios de la competencia ni historial de costos para saber si
siempre fue así.

---

## Algo que no encontramos

El margen bruto no viene bajando: se mantiene entre 31,7 % y 32,0 % en todos los semestres
(`consultas_r8.sql`, consulta extra). Lo que sí se ve es que la tienda **deja de ganar** por
otros lados: descuentos altos en algunos vendedores, una categoría con costo alto y, sobre
todo, plata facturada que no entra a la caja (hallazgo 4).

---

# Tres decisiones

| | Decisión 1 | Decisión 2 | Decisión 3 |
|---|---|---|---|
| **Qué** | Hacer traslados fijos cada semana de la central a las sucursales, según lo que se está vendiendo | Cobrar antes de entregar a las personas, y llamar a los clientes con más de 90 días vencidos | Pagar la meta con margen y no solo con ventas: poner un tope de descuento por vendedor |
| **Prioridad** | Alta: se pierden ventas que ya estaban hechas | Muy alta: es la plata que más falta | Media |
| **Por qué** | Hallazgo 3 | Hallazgo 4 | Hallazgos 1 y 2 |
| **Responsable sugerido** | Jefe de logística | Jefe de cartera con los jefes de sucursal | Gerencia comercial |
| **Riesgo** | Más costo de transporte entre bodegas | Algunas personas pueden dejar de comprar si se les exige pagar antes | Los vendedores pueden vender menos al principio |
| **Cómo seguirlo** | Pedidos pendientes por stock y K11 (agotados en sucursales) | K14 (cartera vencida %) y recaudo sobre facturado | K03 (descuento) por vendedor, K06 (margen %) y K08 (cumplimiento) |
