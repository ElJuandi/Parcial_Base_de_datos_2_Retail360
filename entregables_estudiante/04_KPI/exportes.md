# Los 4 archivos para el tablero web

Salen de las vistas del script 07 del profesor con su script 08. Quedan en la carpeta `export/`
de la raíz, en UTF-8 con encabezado. Cada archivo tiene su propio nivel de detalle (grano), y
**no se deben unir entre sí fila contra fila**: si se pega la meta a las ventas por categoría,
la meta se multiplica (ver reto C12).

| Archivo | Una fila es... | Filas | Total que debe dar |
|---|---|---|---|
| `ventas_mensuales.csv` | mes + sucursal + vendedor + categoría | 4.316 | venta neta 77.065.123.983,86 |
| `metas_mensuales.csv` | mes + sucursal + vendedor | 360 | meta 103.770.000.000,00 |
| `recaudos_mensuales.csv` | mes + sucursal + cliente | 7.583 | recaudo 54.081.947.963,55 |
| `stock_corte.csv` | bodega + producto, al 30/09/2026 | 1.600 | 122.341 unidades |

## Columnas

**ventas_mensuales.csv:** `periodo_yyyymm`, `sucursal_id`, `sucursal`, `vendedor_id`, `vendedor`,
`categoria`, `unidades_net` (vendidas menos devueltas), `venta_neta` (sin IVA, ya con notas
crédito), `costo_venta`, `margen_bruto`, `descuentos`, `neto_con_impuestos` (con IVA).
Otros totales: 90.095 unidades, costo 52.520.620.000,00, margen 24.544.503.983,86,
descuentos 4.908.248.511,84 y neto con IVA 91.707.497.542,68.

**metas_mensuales.csv:** `periodo_yyyymm`, `sucursal_id`, `sucursal`, `vendedor_id`, `vendedor`,
`meta_ventas`. No tiene categoría ni producto.

**recaudos_mensuales.csv:** `periodo_yyyymm` (mes del pago), `sucursal_id`, `sucursal`,
`cliente_key`, `monto_recaudado` (con IVA). Es dinero que entró ese mes; no es el saldo que
deben los clientes.

**stock_corte.csv:** `bodega_id`, `bodega`, `sucursal_id` (vacío en la central), `producto_id`,
`producto`, `categoria`, `existencia_a_corte`. Es una foto al corte: no se puede sumar con
fotos de otras fechas.

## Lo que no viene en estos archivos

- La cartera vencida: está en la vista `dwh.vw_cartera_corte` (script 10), factura por factura.
  Si el tablero web la necesita, hay que exportarla aparte.
- Los pedidos pendientes: no son ventas, están solo en la operación.

## Cómo lo revisamos

`validar_exportes.sql` compara las filas y los totales de cada vista con el modelo. Después
contamos las filas de cada CSV para confirmar que coinciden.
