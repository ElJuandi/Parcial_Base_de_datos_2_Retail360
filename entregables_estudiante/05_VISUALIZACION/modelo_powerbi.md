# Cómo armamos el modelo en Power BI

## Datos

Power BI se conecta a PostgreSQL (`localhost`, base `retail360`, usuario `postgres`) en modo
**Importar**. Trajimos las tablas del modelo de análisis que llenó nuestro ETL:

- **Dimensiones:** `dim_fecha`, `dim_sucursal`, `dim_bodega`, `dim_cliente`, `dim_vendedor`, `dim_producto`.
- **Hechos:** `fact_venta`, `fact_movimiento_inventario`, `fact_meta`, `fact_recaudo`.
- **Vista:** `vw_cartera_corte` (script 10 del profesor), que se usa para la cartera.

En las dimensiones cambiamos el nombre de la columna `nombre` por `sucursal`, `vendedor`,
`cliente`, `producto` y `bodega`, para que se entiendan en los filtros y las tablas.

## Relaciones

Power BI detectó solo las llaves foráneas de la base. Encima de eso hicimos tres cambios:

1. **Quitamos** `dim_vendedor → dim_sucursal`. Abría un segundo camino de la sucursal a las
   ventas (sucursal → vendedor → venta) y por eso Power BI dejaba inactivas las relaciones de
   los vendedores.
2. **Activamos** `fact_venta`, `fact_meta` y `fact_recaudo → dim_vendedor`.
3. **Agregamos** la cartera: `vw_cartera_corte` → `dim_sucursal`, `dim_vendedor` y
   `dim_cliente`, por sus ids.

Todas las relaciones son de uno a varios y filtran en una sola dirección, de la dimensión al
hecho. `dim_bodega → dim_sucursal` se deja, para que el filtro de sucursal también llegue al
inventario.

## Medidas

Las 15 medidas (K01 a K15) siguen al pie de la letra `04_KPI/catalogo_kpi.md`. Las creamos
pegando `powerbi/medidas_y_relaciones.tmdl` en la vista TMDL. Si se pega otra vez, hay que
copiar desde la línea `createOrReplace`. Algunos detalles:

- **K07 y K09 (meta):** quedan vacías si alguien filtra por producto o cliente, porque la meta
  no tiene esos datos (reto C12).
- **K09:** primero arma una fila por vendedor, sucursal y mes, con su meta y su venta, y
  después cuenta cuántas cumplieron. Nunca pega la meta a las líneas de venta.
- **K10 y K11 (inventario):** ignoran cualquier filtro de fecha y toman todos los movimientos
  hasta el 30/09/2026.
- **Columna `antiguedad`:** está en la cartera y agrupa el saldo como el reto C06.

## Páginas

| Página | Qué muestra | Filtros |
|---|---|---|
| 1. Ventas y margen | K01, K05, K06, K03 y K04; ventas por mes; margen % por mes; ventas por categoría; descuento contra margen por vendedor; top de clientes | Mes, sucursal, vendedor, categoría |
| 2. Inventario al corte | K10 y K11; existencias por bodega; matriz categoría por bodega; productos con menos de 3 unidades en sucursales; nota de pedidos pendientes | Sucursal, bodega, categoría (sin mes) |
| 3. Vendedores y metas | K07, K01, K08 y K09; cumplimiento por vendedor con línea en 100 %; meta contra ventas por mes; tabla por vendedor con descuento y margen | Mes, sucursal, vendedor (sin categoría) |
| 4. Facturación, recaudo y cartera | K15, K12, K13 y K14; facturado contra recaudado por mes; cartera por antigüedad; cartera por segmento; clientes con más saldo vencido | Mes, sucursal, vendedor |

## Diferencias con los bocetos de R5

- **Margen % por mes:** el eje no empieza en 0. El margen se mueve entre 31 % y 33 %, y desde
  0 la línea se vería plana. Es una línea, no barras, así que no exagera tamaños.
- **Matriz de cumplimiento por vendedor y mes:** la cambiamos por una tabla por vendedor, que
  también muestra el descuento y el margen.
- **Inventario:** la matriz de categoría por bodega va sin colores, y no hay tarjeta aparte
  para la bodega central. Ese dato sale con el filtro de bodega.
- **Top 10 de clientes:** es la tabla ordenada de mayor a menor venta. No le pusimos el
  filtro de 10.
- **Valor "(En blanco)" en el filtro de sucursal:** aparece porque la bodega central no tiene
  sucursal. No afecta ningún número.
