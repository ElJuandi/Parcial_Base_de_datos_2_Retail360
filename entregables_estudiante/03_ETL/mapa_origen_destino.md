# Mapa origen - destino

De dónde sale cada columna del modelo de análisis. "Llave natural" es el id de la operación
que usamos para saber si una fila ya existe; las llaves `_key` las pone el modelo solo.

## Dimensiones

| Destino (dwh) | Origen (oltp) | Transformación | Llave natural |
|---|---|---|---|
| `dim_fecha` | Todas las fechas de la operación | Se genera un día por fila, desde el 1 de enero del primer año hasta el 31 de diciembre del último (2024 a 2026, 1.096 días). `fecha_key` = AAAAMMDD. Nombres de día y mes en español. | `fecha_key` |
| `dim_sucursal` | `sucursal` | `region` se deduce de la ciudad: Manizales y Pereira = Eje Cafetero, Medellín = Antioquia. | `sucursal_id` |
| `dim_bodega` | `bodega` | `sucursal_key` se busca en `dim_sucursal`. La central queda sin sucursal. | `bodega_id` |
| `dim_cliente` | `cliente` | Se copia igual, incluido `plazo_credito_dias`. | `cliente_id` |
| `dim_vendedor` | `vendedor` | `sucursal_id` pasa a `sucursal_actual_id` y se busca su `sucursal_key`. | `vendedor_id` |
| `dim_producto` | `producto` + `categoria` | Se le pega el nombre de la categoría. Se copian costo estándar y precio de lista. | `producto_id` |

## Hechos

### fact_venta (una fila por línea de factura o de nota crédito)

| Columna destino | Línea de factura | Línea de nota crédito |
|---|---|---|
| `tipo_evento` | `'FACTURA'` | `'NOTA_CREDITO'` |
| `linea_origen_id` | `factura_detalle_id` | `nota_detalle_id` |
| `factura_id` | `factura.factura_id` | `nota_credito.factura_id` |
| `fecha_key` | `factura.fecha_factura` | `nota_credito.fecha_nota` (su propia fecha) |
| sucursal, cliente, vendedor | del `pedido` de la factura | del `pedido` de la factura devuelta |
| `producto_key` | `factura_detalle.producto_id` | el producto de la línea devuelta |
| `unidades` | `cantidad` | `-cantidad` devuelta |
| `valor_bruto` | `round(precio × cantidad, 2)` | igual, en negativo |
| `descuento` | `round(bruto × descuento_pct, 2)` | igual, en negativo |
| `venta_neta` | `bruto - descuento` | igual, en negativo |
| `costo_venta` | `round(costo_unitario × cantidad, 2)` | igual, en negativo |
| `impuesto` | `round(neto × impuesto_pct, 2)` | igual, en negativo |
| `valor_facturado_con_impuesto` | `neto + impuesto` | igual, en negativo |

Llave natural: `tipo_evento` + `linea_origen_id`. Solo entran facturas `EMITIDA`.
La devolución usa el precio, descuento e IVA de la línea original que se vendió.

### fact_movimiento_inventario (una fila por movimiento)

| Columna destino | Origen | Transformación |
|---|---|---|
| `movimiento_id` | `movimiento_inventario.movimiento_id` | Llave natural |
| `fecha_key` | `fecha_movimiento` | AAAAMMDD |
| `bodega_key`, `producto_key` | `bodega_id`, `producto_id` | Se buscan en sus dimensiones |
| `tipo`, `cantidad_delta` | igual | Se copian con su signo (entra +, sale -) |

### fact_meta (una fila por vendedor, sucursal y mes)

| Columna destino | Origen | Transformación |
|---|---|---|
| `meta_id` | `meta_mensual.meta_id` | Llave natural |
| `mes_fecha_key` | `mes` (siempre día 1) | AAAAMMDD |
| `sucursal_key`, `vendedor_key` | `sucursal_id`, `vendedor_id` | Se buscan en sus dimensiones |
| `monto_meta` | igual | Se copia |

### fact_recaudo (una fila por pago)

| Columna destino | Origen | Transformación |
|---|---|---|
| `pago_id` | `pago.pago_id` | Llave natural |
| `factura_id` | `pago.factura_id` | Se copia |
| `fecha_key` | `fecha_pago` (no la de la factura) | AAAAMMDD |
| sucursal, cliente, vendedor | del `pedido` de la factura pagada | Se buscan en sus dimensiones |
| `monto_recaudado` | `monto` | Se copia |

## Lo que no pasa al modelo

- `pedido` y `pedido_detalle` como tales: un pedido no es una venta. Solo se usan para saber
  la sucursal, el cliente y el vendedor de cada factura.
- `pago.medio`, `nota_credito.motivo`, `pedido.motivo` y `movimiento_inventario.referencia`:
  no los pide ninguna de nuestras preguntas del negocio.
- `factura.fecha_vencimiento`: la cartera se calcula aparte con el script 10 del profesor.
