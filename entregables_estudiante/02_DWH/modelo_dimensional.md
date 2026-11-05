# Modelo para análisis

Pasamos de las 15 tablas de la operación a un modelo en constelación: 4 tablas de hechos (lo que
pasó y cuánto) que comparten 6 dimensiones (con quién, cuándo, dónde y qué).
El diagrama está en `diagrama_estrella.png`.

## Las 4 tablas de hechos

Para cada una respondimos las cuatro preguntas de la infografía.

| Hecho | ¿Qué es una fila? | ¿Qué se mide? | ¿Desde dónde se mira? | ¿Qué historia se guarda? |
|---|---|---|---|---|
| `fact_venta` | Una línea de factura o una línea de nota crédito | Unidades, valor bruto, descuento, venta neta, costo, impuesto | Fecha, producto, cliente, vendedor, sucursal | Cada venta y cada devolución con su propia fecha. Las devoluciones van en negativo y la factura original no se toca |
| `fact_movimiento_inventario` | Un movimiento de un producto en una bodega | Cantidad que entra o sale | Fecha, producto, bodega | Todos los movimientos; el saldo se calcula sumándolos hasta una fecha |
| `fact_meta` | La meta de un vendedor en una sucursal en un mes | Valor de la meta | Mes, vendedor, sucursal | Una meta por mes; si cambia, se actualiza |
| `fact_recaudo` | Un pago | Valor pagado | Fecha del pago, cliente, vendedor, sucursal | Cada pago en su fecha, aunque sea distinta a la de la factura |

## Matriz bus (qué dimensión usa cada hecho)

| Hecho | Fecha | Producto | Cliente | Vendedor | Sucursal | Bodega |
|---|---|---|---|---|---|---|
| Venta | Sí | Sí | Sí | Sí | Sí | No |
| Movimiento de inventario | Sí | Sí | No | No | (por la bodega) | Sí |
| Meta | Sí (mes) | No | No | Sí | Sí | No |
| Recaudo | Sí | No | Sí | Sí | Sí | No |

Las dimensiones son las mismas para todos los hechos. Por eso se pueden comparar, por ejemplo,
ventas contra metas por vendedor y mes, o inventario contra ventas por producto.

## Qué se puede sumar y qué no

| Medida | ¿Se suma? |
|---|---|
| Venta neta, costo, unidades, descuento, recaudo | Sí, por cualquier dimensión |
| Meta | Solo por vendedor, sucursal y mes. No por producto ni por cliente |
| Movimientos de inventario | Sí. Pero el saldo (existencias) es una foto: se suma entre bodegas o productos, nunca entre meses |
| Margen %, cumplimiento %, % de descuento | No. Se calculan dividiendo totales (por ejemplo, margen total / venta total) |

## Dimensiones

| Dimensión | Qué trae | Qué le agregamos al modelo del profesor |
|---|---|---|
| `dim_fecha` | Fecha, año, mes, trimestre | Día del mes, nombre del día y del mes |
| `dim_producto` | Nombre, categoría | Costo estándar y precio de lista |
| `dim_cliente` | Nombre, segmento, ciudad | Días de crédito |
| `dim_vendedor` | Nombre, sucursal actual | Enlace a la dimensión sucursal y fecha de ingreso |
| `dim_sucursal` | Nombre, ciudad | Región (sacada de la ciudad: Manizales y Pereira = Eje Cafetero, Medellín = Antioquia) |
| `dim_bodega` | Nombre, tipo | Enlace a la dimensión sucursal (la central queda sin sucursal) |

No agregamos el "cargo" del vendedor que aparece en la infografía, porque ese dato no existe.
Los cambios están en `ajustes_dwh_grupo.sql` y se corren después del script 04 del profesor.

## Por qué usamos claves propias (sustitutas)

Cada dimensión tiene su propia clave (`cliente_key`, `producto_key`, etc.) además del id que
viene de la operación. Así el modelo no depende de cómo se numeran las cosas en la operación,
las uniones son más rápidas con números enteros y, si algún día se quiere guardar historia de
cambios (como abajo), se puede tener más de una fila para el mismo cliente o vendedor.
La fecha usa como clave el número `AAAAMMDD` (por ejemplo 20250315), que es fácil de leer.

## Si un vendedor cambia de sucursal (propuesta SCD tipo 2)

Hoy `dim_vendedor` solo guarda la sucursal actual. Si un vendedor se pasa de Manizales a Pereira,
todas sus ventas viejas quedarían como si fueran de Pereira.

La propuesta es guardar una fila por cada etapa del vendedor, con `valido_desde`, `valido_hasta`
y `es_actual`. Cada venta queda unida a la versión del vendedor que estaba vigente ese día.

- **Lo que se gana:** las ventas viejas siguen contando para la sucursal donde se hicieron.
- **Lo que se complica:** el ETL tiene que buscar la versión correcta según la fecha, para contar
  vendedores hay que usar el id y no la clave, y las metas deben quedar con la versión correcta.

En los datos actuales ningún vendedor cambió de sucursal, así que por ahora no se implementa.

## La meta no se puede pegar a cada venta

En `demo_meta_duplicada.sql` lo comprobamos con los datos reales:

- La meta total de verdad es de **103.770 millones** (360 metas).
- Si se une cada meta con cada línea vendida de ese vendedor y mes, la meta se repite y la suma da
  **8,7 billones**, unas 84 veces más. Por ejemplo, la primera meta (300 millones) se repite 57
  veces.
- La forma correcta es sumar primero las ventas por vendedor, sucursal y mes y luego unirlas con
  la meta. Así da una venta de 77.706 millones contra 103.770 millones de meta: un cumplimiento
  de **74,9 %** (todavía sin restar devoluciones; con ellas se calcula en R3).
