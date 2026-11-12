# Informe final · Retail 360

**Parcial de Bases de Datos II** · Universidad de Manizales · Ingeniería de Sistemas y Telecomunicaciones

**Grupo:** Juan Diego Ortiz, Adrian Daniel Argotte, Miguel Andrés Pava, Jerónimo Soto y David González.

---

## 1. De qué se trata

Retail 360 es una tienda de tecnología con 3 sucursales (Manizales, Pereira y Medellín), una
bodega central y 15 vendedores. El caso trae dos años de datos, de octubre de 2024 a septiembre
de 2026: pedidos, facturas, devoluciones, pagos, movimientos de inventario y metas de venta.

La pregunta que nos pusieron fue: **¿por qué la empresa vende más pero gana menos, se queda sin
productos en algunas bodegas y no logra cobrar todo lo que factura?**

Para responderla montamos la base de la operación, la pasamos a un modelo pensado para
analizar, definimos los indicadores y armamos dos tableros: uno en Power BI y una página web
que funciona sin internet. Al final sacamos hallazgos y propusimos decisiones.

## 2. Cómo lo hicimos

Trabajamos por etapas y no pasábamos a la siguiente hasta tener la anterior revisada. Todo
corrió en el computador de Miguel, con PostgreSQL local.

| Etapa | Qué hicimos | Dónde está |
|---|---|---|
| R0 | Revisamos que el computador tuviera todo y que el paquete del profesor estuviera completo | `00_ARRANQUE` |
| R1 | Cargamos la base de la operación (15 tablas), dibujamos el diagrama y escribimos las reglas del negocio | `01_OLTP` |
| R2 | Diseñamos el modelo de análisis: 4 tablas de hechos y 6 dimensiones | `02_DWH` |
| R3 | Escribimos nuestro propio proceso de carga (ETL) y lo probamos de varias formas | `03_ETL` |
| R4 | Resolvimos los 12 retos SQL y sacamos los archivos para el tablero web | `04_KPI` |
| R5 | Definimos 15 indicadores con su fórmula y los aprobamos en grupo antes de abrir Power BI | `04_KPI` |
| R6 | Armamos el tablero de Power BI con 4 páginas | `05_VISUALIZACION` |
| R7 | Hicimos con IA la página web sin internet | `05_VISUALIZACION/web` |
| R8 | Sacamos 5 hallazgos y 3 decisiones | `06_INTERPRETACION` |

Algunas decisiones que vale la pena contar:

- **Hicimos nuestro propio ETL** en vez de usar el del profesor. Revisa los datos antes de
  cargar y, al terminar, compara el modelo con la operación al centavo. Si algo no cuadra,
  deshace todo. Al final lo comparamos fila por fila con el del profesor y quedó igual.
- **Las devoluciones no borran la venta:** entran como filas negativas con su propia fecha.
- **La meta nunca se pega a cada venta.** En R2 mostramos por qué: si se hace, la meta pasa
  de 103.770 millones a 8,7 billones.
- **El inventario y la cartera son fotos al corte** (30/09/2026). No se suman fechas.

## 3. ¿Los números son confiables?

Antes de sacar conclusiones nos aseguramos de que los datos no se dañaran en el camino:

- **Conteos:** el modelo quedó con exactamente las filas que esperaba la guía: 30.750 de ventas
  (facturas y devoluciones), 40.628 de inventario, 360 de metas y 7.854 de pagos.
- **Venta neta:** 77.065.123.983,86 pesos en la operación y en el modelo, con 0,00 de diferencia.
- **Repetir la carga:** al correr la carga varias veces no se duplicó nada.
- **Pruebas a propósito:** dañamos datos a propósito y la carga se detuvo como debía.
- **Las tres herramientas:** los 15 indicadores dan el mismo resultado en SQL, en Power BI y en
  la página web, con los mismos filtros. Lo probamos con dos escenarios: toda la empresa, y
  Pereira en septiembre de 2026.

## 4. Los indicadores principales

Todo el periodo, toda la empresa. Ventas y margen sin IVA; recaudo y cartera con IVA.

| Indicador | Valor |
|---|---|
| Ventas netas | 77.065 millones |
| Margen bruto | 24.545 millones (31,85 %) |
| Descuento promedio | 5,99 % |
| Devoluciones | 0,81 % de las unidades |
| Meta de ventas | 103.770 millones |
| Cumplimiento de la meta | 74,27 % |
| Metas mensuales cumplidas | 20,28 % |
| Unidades en inventario al corte | 122.341 |
| Productos agotados en sucursales | 7 |
| Facturado con IVA | 91.707 millones |
| Recaudado | 54.082 millones |
| Por cobrar al corte | 37.626 millones (97,57 % vencido) |

## 5. Lo que encontramos

1. **Nadie llega a la meta.** Se vendió el 74 % de lo esperado, y solo 1 de cada 5 metas
   mensuales se cumplió. Ningún vendedor llegó al 100 % en los dos años.
2. **Dos vendedores cumplen regalando margen.** Dan 12 % de descuento cuando el resto da 5 %, y
   su margen baja de 32,5 % a 27 %. Calculamos que eso son unos 500 millones de margen que no
   se ganaron.
3. **El producto sí estaba, pero en otra bodega.** Hubo 839 pedidos frenados por falta de
   stock. En todos los casos donde faltaba en la sucursal, la bodega central sí tenía.
4. **La plata no está entrando.** Solo se recaudó el 59 % de lo facturado. De lo que falta por
   cobrar, casi todo ya está vencido y el 72 % lleva más de seis meses. La mayor parte la deben
   clientes que deberían pagar de contado.
5. **Redes es la categoría que menos deja.** Tiene 25,8 % de margen contra 30 % a 34 % de las
   demás, y no es por descuentos: su costo es el más alto.

Algo que nos sorprendió: **el margen no viene bajando.** Se mantiene cerca de 32 % todo el
tiempo. Entonces la respuesta a la pregunta del caso no es que cada venta deje menos: la tienda
pierde por los descuentos de algunos vendedores, por una categoría con costo alto y, sobre
todo, porque mucha de la plata que factura nunca llega a la caja.

El detalle de cada hallazgo, con la consulta que lo respalda, está en
`06_INTERPRETACION/hallazgos.md`.

## 6. Lo que recomendamos

| Decisión | Por qué | Cómo saber si funciona |
|---|---|---|
| Hacer traslados fijos cada semana de la bodega central a las sucursales | Se pierden ventas teniendo el producto | Menos pedidos frenados por stock y menos productos agotados en sucursales |
| Cobrar antes de entregar a las personas y llamar a quienes deben hace más de 90 días | Es la plata que más falta | Baja la cartera vencida y sube el recaudo sobre lo facturado |
| Medir a los vendedores también por margen y poner un tope de descuento | La meta de solo ventas premia vender barato | Descuento por vendedor, margen % y cumplimiento |

## 7. Lo que no se puede concluir

- **Utilidad:** los datos son sintéticos y no traen arriendos, nómina ni otros gastos. Por eso
  hablamos de margen bruto y no de utilidad.
- **Causas:** son hipótesis. No sabemos cómo se pusieron las metas ni si los descuentos altos
  estaban autorizados.
- **Fechas sin hora:** en algunos pedidos no se puede saber si el inventario llegó antes o
  después del pedido.
- **Página web:** no permite ver el recaudo por vendedor, porque el archivo que exporta el
  profesor no trae ese dato. Power BI sí lo permite.

## 8. Uso de IA

Como lo pide la guía, declaramos que usamos IA (Claude) como apoyo: para ordenar ideas,
revisar borradores y, en R7, para generar la página web, que es lo que pide esa etapa. Nada lo
dimos por bueno sin correrlo y revisarlo nosotros con SQL y con las pruebas del profesor. El
detalle, etapa por etapa, está en `IA/registro_ia.md`.

## 9. Cómo lo puede repetir otra persona

Nosotros lo corrimos todo con 8 archivos `.bat`, de R0 a R8, en el computador de Miguel. Cada
uno pide la contraseña de PostgreSQL y deja lo que salió en la carpeta `salidas` de su etapa.
Si otra persona sigue el README principal con PostgreSQL, Python y Power BI, debería llegar a
los mismos números de este informe.

## 10. Evidencias

- Las salidas de cada etapa (`salidas/salida_rX.txt` y `00_ARRANQUE/evidencia_entorno.txt`),
  con fecha y hora de cuando las corrimos.
- El acuerdo de indicadores firmado por los 5 (`04_KPI/acuerdo_kpi.md`).
- El tablero `05_VISUALIZACION/Retail360.pbix` y la página `tablero_retail360.html`.
- Las comparaciones número por número (`equivalencia_r6.md` y `equivalencia_r7.md`).
- El historial de commits del repositorio, una etapa tras otra.
