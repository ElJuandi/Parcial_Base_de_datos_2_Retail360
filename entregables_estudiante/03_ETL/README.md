# R3 - ETL

Aquí está nuestro procedimiento para pasar los datos de la operación al modelo de análisis.
Se usa igual que el del profesor: `CALL dwh.cargar_retail360();`. No usamos su ETL de
referencia; lo escribimos nosotros y al final lo comparamos con el suyo.

## Archivos

- `etl_retail360.sql` - el procedimiento, comentado y organizado en los 5 pasos de la infografía.
- `flujo_etl.md` y `flujo_etl.png` - el diagrama del flujo.
- `mapa_origen_destino.md` - de dónde sale cada columna del modelo.
- `pruebas_y_errores.md` - las pruebas, la comparación con el ETL del profesor y qué pasa cuando algo falla.
- `carga_incremental.md` - cómo haríamos para cargar solo lo nuevo.
- `consultas_r3.sql` - nuestras revisiones después de cargar, incluidas dos pruebas que dañan algo a propósito.
- `ejecutar_r3.bat` - el archivo con el que corrimos todo de una vez.
- `salidas/salida_r3.txt` - lo que salió al correrlo.

## Cómo lo corrimos

Después de tener R1 y R2, corrimos `ejecutar_r3.bat` con la contraseña de PostgreSQL. Lo
armamos para que siguiera este orden: nuestro ETL, después los scripts 05b, 06, 09, 12 y 13
del profesor y al final nuestras revisiones.

## Cuándo damos R3 por terminada

- Las pruebas 06, 09, 12 y 13 del profesor pasan.
- Los conteos dan 30.750, 40.628, 360 y 7.854, y la venta neta tiene diferencia 0,00.
- La bitácora muestra la carga y que repetirla no cambia nada.

## Resultado

Lo corrimos el 4 de noviembre de 2026 en el computador de Miguel, sin errores.

- La primera carga dejó 30.750 filas de venta (30.224 de facturas y 526 de notas crédito),
  40.628 movimientos, 360 metas y 7.854 pagos.
- La venta neta es de 77.065.123.983,86 en la operación y en el modelo: diferencia 0,00.
- Pasaron las pruebas 06, 09 (`ACEPTACION OK`), 12 (`PRUEBA IDEMPOTENCIA OK`) y 13 (la meta
  subió a 330 millones durante la prueba y volvió a 300 millones después del ROLLBACK).
- Al repetir la carga, la bitácora mostró 0 filas nuevas y 0 cambiadas.
- Las dos pruebas negativas detuvieron la carga como esperábamos y no dejaron cambios.
- Las 7 revisiones del origen dieron 0 y los 9 controles de la conciliación dieron diferencia 0.
