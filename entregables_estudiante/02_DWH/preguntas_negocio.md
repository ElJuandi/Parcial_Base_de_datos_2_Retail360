# Preguntas del negocio

Antes de diseñar las tablas, escribimos qué quiere saber la gerencia. Cada pregunta nos dice qué
medir, por qué lo queremos ver y qué cuidado hay que tener.

| # | Pregunta | Qué medimos | Lo vemos por | Cuidado | Qué dato falta |
|---|---|---|---|---|---|
| 1 | ¿Cuánto vendimos cada mes, por sucursal y categoría, ya restando devoluciones? | Venta neta | Fecha, sucursal, producto | Las devoluciones restan en la fecha de la nota crédito, no en la de la factura | Nada |
| 2 | ¿El margen baja aunque las ventas suban? | Margen bruto y margen % | Fecha, categoría | El margen bruto no es la utilidad | Gastos de nómina, arriendo, transporte |
| 3 | ¿Cuánto descuento damos y quién lo da? | Descuento y % de descuento | Vendedor, categoría, fecha | El % se calcula sobre el total, no promediando porcentajes | Nada |
| 4 | ¿Qué vendedores cumplen la meta y con qué margen? | Venta neta contra meta, margen % | Vendedor, sucursal, mes | La meta es por mes; no se puede repetir en cada venta ni partir por categoría | Nada |
| 5 | ¿Cuánto inventario hay en cada bodega a una fecha? | Existencias | Bodega, producto, fecha de corte | Es una foto a una fecha; no se suma mes tras mes | Valor del inventario con costo histórico |
| 6 | ¿Falta producto en una sucursal mientras sobra en otra bodega? | Existencias y pedidos pendientes por stock | Bodega, producto, fecha | Comparar a la misma fecha | Los pedidos pendientes no quedan en el modelo de análisis (solo en la base de la operación) |
| 7 | ¿Cuánto cobramos cada mes y cuánto nos deben a la fecha de corte? | Recaudo y saldo de cartera | Fecha, cliente, sucursal | Lo cobrado en un mes no se resta de lo facturado en ese mes para sacar la deuda | Nada (la deuda se saca por factura) |
| 8 | ¿Qué clientes concentran las ventas y cuáles deben más? | Venta neta y saldo | Cliente | Ordenar de mayor a menor y ver cuántos hacen el 80 % | Nada |
| 9 | ¿Qué productos se devuelven más? | Unidades devueltas sobre unidades vendidas | Producto, categoría | Definir bien sobre qué se divide | Nada |
| 10 | ¿Las empresas pagan distinto que las personas? | Recaudo sobre lo facturado | Tipo de cliente | Las personas pagan de contado y las empresas a 30 días | Nada |
