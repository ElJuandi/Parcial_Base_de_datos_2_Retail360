# Reglas del negocio

Estas son las reglas con las que funciona la tienda y cómo se cuidan en la base de datos.

| # | Regla | Cómo se cuida en la base |
|---|---|---|
| 1 | Un pedido puede quedar facturado, pendiente por falta de stock, pendiente por crédito o cancelado. Que exista un pedido no significa que haya una venta. | `pedido.estado` solo acepta esos 4 valores. |
| 2 | Solo los pedidos facturados tienen factura, y cada pedido tiene como máximo una factura. | `factura.pedido_id` es único. El script 03 revisa que no haya facturas de pedidos no facturados. |
| 3 | Una factura puede tener varios productos. Cada línea de la factura sale de una línea del pedido, con el mismo producto y la misma cantidad. | `factura_detalle.pedido_detalle_id` es único. El script 03 revisa que coincidan. |
| 4 | El precio de venta debe ser mayor a cero y el costo no puede ser negativo. | Restricciones `CHECK` en `producto` y `factura_detalle`. |
| 5 | El descuento de una línea va de 0 % a 80 % y el impuesto de 0 % a 100 %. En los datos, el IVA siempre es 19 %. | `CHECK` en `descuento_pct` e `impuesto_pct`. |
| 6 | Una devolución no borra la factura: se registra aparte como nota crédito, con su propia fecha. | Tablas `nota_credito` y `nota_credito_detalle`. |
| 7 | No se puede devolver más de lo que se vendió en esa línea. | `cantidad > 0` y el script 03 revisa que lo devuelto no pase de lo vendido. |
| 8 | Un pago es dinero que efectivamente entró. Puede ser parcial y su fecha no tiene que ser la de la factura. | `pago` va contra la factura, con `monto > 0` y su propia `fecha_pago`. |
| 9 | La factura tiene fecha de vencimiento, que nunca puede ser antes de la fecha de la factura. Los clientes persona pagan de contado (0 días) y las empresas tienen 30 días. | `CHECK (fecha_vencimiento >= fecha_factura)` y `plazo_credito_dias` entre 0 y 90. |
| 10 | El inventario se calcula sumando movimientos: lo que entra suma y lo que sale resta. | `CHECK` que obliga a que entradas sean positivas y salidas negativas según el tipo. |
| 11 | Un traslado entre bodegas mueve unidades de un lado a otro pero no cambia el total de la empresa. | Cada traslado tiene una salida y una entrada por la misma cantidad. |
| 12 | Ninguna bodega puede terminar con existencias negativas. | El script 03 revisa que ningún saldo final quede en negativo. |
| 13 | La bodega central no pertenece a ninguna sucursal; las bodegas locales sí. | `CHECK` en `bodega`: central sin sucursal, local con sucursal. |
| 14 | Las metas son por vendedor, sucursal y mes. No puede haber dos metas para el mismo vendedor, sucursal y mes. | `UNIQUE (vendedor_id, sucursal_id, mes)` y el mes siempre es el día 1. |
| 15 | El margen bruto es venta sin impuesto menos costo. No es la utilidad de la empresa, porque no incluye arriendos, nómina ni otros gastos. | Regla para el análisis (se usa desde R2). |
