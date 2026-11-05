# Propuesta de carga incremental

Nuestro ETL hoy es una **carga completa repetible**: cada vez lee toda la operación y, gracias
a `ON CONFLICT`, no duplica nada. Eso funciona bien con estos datos (unos 80.000 registros en
pocos segundos), pero no es una carga incremental. Si la tienda creciera, leer todo cada noche
sería lento. Así lo haríamos para leer solo lo nuevo:

## 1. Marca de agua (watermark)

- Agregar a las tablas de la operación una columna `actualizado_en` (fecha y hora del último
  cambio), que se llene sola con un trigger en cada INSERT o UPDATE.
- Guardar en una tabla `etl.control_carga` la marca de agua de cada fuente: hasta qué momento
  ya se cargó.
- Cada carga lee solo las filas con `actualizado_en` mayor que la marca guardada y, al
  terminar bien, mueve la marca al valor más alto que leyó.

## 2. Cambios tardíos

- Una nota crédito o un pago puede llegar meses después de la factura. Como cada uno entra con
  su propia fecha, no hay que tocar la venta original: se suma una fila nueva y ya.
- Si alguien corrige un dato viejo (por ejemplo, el valor de una meta), su `actualizado_en`
  cambia y la siguiente carga lo toma. `ON CONFLICT` actualiza la fila que ya existía.
- Para no perder registros que se guardan justo mientras corre la carga, se leería con un
  pequeño margen hacia atrás (por ejemplo, 10 minutos antes de la marca). `ON CONFLICT` se
  encarga de que eso no duplique.
- Los borrados en la operación no se ven con la marca de agua. Lo correcto es no borrar
  documentos (anular la factura en vez de borrarla), que es justo la regla del negocio.

## 3. Control de duplicados

- Seguimos usando las llaves naturales (`tipo_evento + linea_origen_id`, `movimiento_id`,
  `meta_id`, `pago_id`) con `UNIQUE` en el modelo. Aunque una fila llegue dos veces, queda una.
- La conciliación del paso 5 se haría por el rango cargado (por ejemplo, el mes) en vez de
  sobre todo el histórico.

## 4. Registro de errores que no se pierda

- Hoy, si la carga falla, la fila de la bitácora se deshace con todo lo demás.
- En la versión incremental quien lanza la carga (un programador de tareas o un script) haría
  tres pasos separados: abrir la corrida en la bitácora y confirmarla, llamar a la carga y,
  según el resultado, marcar la corrida como OK o como ERROR con el mensaje. Así el fallo queda
  guardado aunque la carga se haya deshecho.
- Otra opción dentro de PostgreSQL es escribir el error con `dblink`, que abre una conexión
  aparte y confirma ese registro por su cuenta.

## Resumen

| Tema | Hoy (carga completa) | Propuesta (incremental) |
|---|---|---|
| Qué lee | Toda la operación | Solo lo cambiado después de la marca de agua |
| Duplicados | `ON CONFLICT` | `ON CONFLICT` + margen de lectura |
| Datos tardíos | Entran solos porque se lee todo | Entran por su `actualizado_en` |
| Errores | En el archivo de salida | En la bitácora, guardados aparte de la carga |
