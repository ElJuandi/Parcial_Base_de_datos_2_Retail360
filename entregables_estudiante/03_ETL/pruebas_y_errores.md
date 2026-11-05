# Pruebas y diagnóstico de errores

## Pruebas que corre `ejecutar_r3.bat`

| # | Prueba | Script | Qué debe salir |
|---|---|---|---|
| 1 | Primera carga | `sql/05b_ejecutar_etl.sql` | Bitácora en OK con 30.750 ventas, 40.628 movimientos, 360 metas y 7.854 pagos |
| 2 | Conteos origen contra modelo | `sql/06_validar_dwh.sql` | Los mismos números a los dos lados y diferencia 0,00 en la venta neta |
| 3 | Aceptación del profesor | `sql/09_pruebas_aceptacion.sql` | `ACEPTACION OK`: conteos, neto al centavo, metas sin repetir, inventario sin negativos |
| 4 | Repetir la carga | `sql/12_prueba_idempotencia.sql` | `PRUEBA IDEMPOTENCIA OK`: dos cargas más y nada cambia |
| 5 | Cambio que se deshace | `sql/13_ensayo_actualizacion_controlada.sql` | La meta 1 sube 10 % durante la prueba y vuelve a su valor después del ROLLBACK |
| 6 | Revisión del origen | `consultas_r3.sql` | Las 7 revisiones en 0 |
| 7 | Conciliación | `consultas_r3.sql` | 9 controles con diferencia 0 |
| 8 | Prueba negativa 1 | `consultas_r3.sql` | Con un pago mal fechado la carga se detiene antes de empezar |
| 9 | Prueba negativa 2 | `consultas_r3.sql` | Con una venta de más en el modelo la carga se deshace |

Las pruebas 5, 8 y 9 dañan algo a propósito, pero dentro de un bloque que se deshace solo.
Al final la operación y el modelo quedan como estaban.

## Comparación con el ETL de referencia del profesor

Antes de entregarlo comparamos, fila por fila, lo que deja nuestro ETL contra lo que deja
`sql/05_etl_referencia.sql` en una copia aparte de la base. Los 4 hechos quedaron idénticos.

| | Referencia del profesor | Nuestro ETL |
|---|---|---|
| Resultado en los hechos | 30.750 / 40.628 / 360 / 7.854 | Igual, fila por fila |
| Organización | Un solo bloque | 5 pasos, cada uno en su función o vista |
| Revisión antes de cargar | No tiene | 7 revisiones; si una falla, no carga |
| Revisión después de cargar | No tiene (se hace con 06 y 09 aparte) | Concilia filas y pesos; si no cuadra, deshace |
| Cálculo de montos | Repetido para facturas y para notas | Una sola función para los dos |
| Repetir la carga | Reescribe todas las filas aunque no cambien | Solo reescribe las que cambiaron |
| Bitácora | Total de filas | Total de filas + cuántas nuevas y cuántas cambiadas |
| Columnas extra de R2 | No las llena | Las llena (región, día, plazo de crédito, etc.) |
| Días en `dim_fecha` | 2024 a 2027 fijo | Según las fechas de los datos (2024 a 2026) |

## Diagnóstico de errores

| Qué puede fallar | Qué pasa | Cómo lo vemos |
|---|---|---|
| Un dato malo en la operación (pago antes de la factura, devolución mayor a lo vendido, etc.) | La carga no arranca y nada cambia en el modelo | Mensaje `Carga detenida, el origen tiene problemas -> ...` con el nombre del problema y cuántas filas |
| Se pierde una fila en el camino (por ejemplo, un producto que no llegó a su dimensión) o sobra una | La carga se deshace completa | Mensaje `Carga deshecha, el modelo no cuadra con el origen -> ...` con origen y modelo |
| Se corre dos veces seguidas | No pasa nada malo: no se duplica | La bitácora de la segunda dice `+0 ~0` |
| Falla PostgreSQL a mitad de camino | Se deshace todo, porque el CALL es una sola transacción | El error queda en `salidas/salida_r3.txt` |

**Algo que hay que saber de la bitácora.** Cuando la carga falla, la fila de la bitácora
también se deshace, porque está en la misma transacción. Por eso la bitácora solo guarda las
cargas que terminaron bien. El registro de los fallos queda afuera, en el archivo de salida que
genera nuestro `.bat`. Dejamos así el procedimiento a propósito: si hiciera COMMIT por dentro
no funcionarían las pruebas 12 y 13 del profesor, que lo llaman dentro de una transacción.

**Errores que encontramos con los datos reales:** ninguno. Las 7 revisiones dan 0 y no hay
facturas anuladas.
