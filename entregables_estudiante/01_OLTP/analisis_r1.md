# R1 - Qué encontramos

Corrimos todo el 4 de noviembre de 2026 en el computador de Miguel. Salió sin errores
(ver `salidas/salida_r1.txt`).

## Los datos cargaron bien

- Las 15 tablas tienen exactamente las filas que dice la guía.
- Los 4 controles del script 03 dieron 0: no hay facturas de pedidos sin facturar, las líneas de
  la factura coinciden con las del pedido, ninguna devolución pasa de lo vendido y ninguna bodega
  quedó en negativo.

## Pedido, factura y pago no son lo mismo

| Paso | Cantidad | Qué significa |
|---|---|---|
| Pedidos | 12.000 | Lo que pidieron los clientes. |
| Facturados | 10.019 | El 83,5 %. Los otros 1.981 no llegaron a venta: 862 esperan aprobación de crédito, 839 no tenían stock en la bodega y 280 se cancelaron. |
| Facturas con algún pago | 7.854 | El 78,4 % de las facturas. Hay 2.165 facturas sin ningún pago. |
| Pagadas completas | 3.184 | De las facturas con pago, 4.670 están pagadas solo en parte. |

Por eso no se puede contar un pedido como venta ni una factura como plata recibida. Cada uno se
mide por separado.

## Inventario

- La empresa tiene 122.341 unidades en total. La bodega central guarda 46.526 (38 %) y las tres
  locales entre 23.598 y 26.282 cada una.
- Hubo 1.658 traslados entre bodegas que movieron 5.672 unidades. La salida de una bodega y la
  entrada en la otra suman 0, así que el total de la empresa no cambia: solo cambia dónde están
  las unidades.
- Las fechas no tienen hora. Si un mismo día hubo una venta y un traslado, no sabemos cuál pasó
  primero, así que no se puede saber el saldo exacto a mitad del día.

## Descuentos

El 83,7 % de las líneas de factura tiene algún descuento y el más alto es de 35 %. Esto lo vamos a
mirar con cuidado en las siguientes etapas, porque puede explicar por qué el margen no crece aunque
se venda más.
