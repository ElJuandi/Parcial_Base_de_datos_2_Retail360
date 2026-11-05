# Flujo del ETL

Así viajan los datos desde la operación hasta el modelo de análisis cuando se corre
`CALL dwh.cargar_retail360();`. La imagen `flujo_etl.png` es el mismo diagrama.

```mermaid
flowchart TD
    A["CALL dwh.cargar_retail360()"] --> B["Bitácora: se abre la corrida"]
    B --> C["Paso 1 - Extraer<br/>vistas etl.v_venta, v_inventario, v_meta, v_recaudo"]
    C --> D{"Paso 2 - Validar el origen<br/>etl.revisar_origen()"}
    D -- "hay problemas" --> X["Se detiene<br/>no se carga nada"]
    D -- "todo en 0" --> E["Paso 3 - Reglas del negocio<br/>etl.montos_linea(): bruto, descuento, neto, IVA<br/>notas crédito en negativo con su fecha"]
    E --> F["Paso 4 - Granularidad<br/>una fila por línea, movimiento, meta o pago"]
    F --> G["Paso 5a - Dimensiones<br/>fecha, sucursal, bodega, cliente, vendedor, producto"]
    G --> H["Paso 5b - Hechos<br/>venta, inventario, meta, recaudo<br/>ON CONFLICT: no duplica"]
    H --> I{"Paso 5c - Conciliar<br/>etl.conciliar()"}
    I -- "no cuadra" --> Y["Se deshace toda la carga"]
    I -- "cuadra al centavo" --> J["Bitácora: OK con filas nuevas y cambiadas"]
```

## En palabras

1. **Extraer.** Unas vistas leen la operación tal cual. No copian nada, solo juntan las tablas
   que se necesitan (por ejemplo, la línea de factura con su factura y su pedido).
2. **Validar.** Antes de tocar el modelo se revisan 7 cosas que la base de la operación no
   impide sola, como un pago con fecha anterior a la factura. Si aparece una, la carga no arranca.
3. **Reglas del negocio.** Una sola función calcula los valores de cada línea, así las ventas
   y las devoluciones usan exactamente el mismo redondeo. Las devoluciones entran en negativo.
4. **Granularidad.** Cada hecho tiene su propio nivel de detalle y su propia fecha. Nada se
   mezcla: la meta no se pega a las ventas y el inventario no se convierte en ventas.
5. **Cargar y revisar.** Primero las dimensiones y después los hechos. Al final se compara
   el modelo con la operación (filas y pesos). Si algo no cuadra, se deshace todo.
