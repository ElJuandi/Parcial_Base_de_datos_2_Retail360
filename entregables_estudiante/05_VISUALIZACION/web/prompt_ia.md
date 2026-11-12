# Cómo usamos la IA para la página web (R7)

**Herramienta:** Claude (Anthropic), en una sesión de Cowork con acceso al repositorio.

## Lo que le pedimos

Partimos del prompt sugerido en la guía (sección 8.3) y le agregamos lo nuestro:

> Genera un único HTML offline para Retail 360 usando los CSV analíticos de `export/` y el
> contrato de KPI de `04_KPI/catalogo_kpi.md`. Requisitos: CSS y JS embebidos, sin API, CDN ni
> fetch; datos embebidos; 4 tableros (comercial, stock, metas, recaudos); filtros; fecha de
> corte visible; definiciones de los KPI visibles y validación de totales. No unas hechos de
> distinta granularidad creando duplicaciones. Primero presenta el mapeo KPI → archivo →
> cálculo e indica qué no se puede calcular. No declares pruebas que no hayas ejecutado.
> Adicional: usa las mismas fórmulas aprobadas en R5, los mismos escenarios A y B, y deja
> un script que regenere la página desde los CSV.

## Mapeo indicador → archivo → cálculo

| KPI | Archivo | Cálculo en la página |
|---|---|---|
| K01, K02, K05, K06, K15 | `ventas_mensuales.csv` | Sumas de venta neta, unidades, margen y neto con IVA; K06 = K05 / K01 |
| K03 | `ventas_mensuales.csv` | descuentos / (venta neta + descuentos), porque el bruto es neto + descuento |
| K04 | `unidades_mensuales.csv` (nuevo) | devueltas / facturadas |
| K07, K08, K09 | `metas_mensuales.csv` + ventas | La venta se resume a mes + sucursal + vendedor antes de cruzarla con la meta |
| K10, K11 | `stock_corte.csv` | Suma de existencias; agotados = bodega local con existencia ≤ 0 |
| K12 | `recaudos_mensuales.csv` | Suma de pagos por mes de pago |
| K13, K14 | `cartera_corte.csv` (nuevo) | Suma del saldo por factura; vencida / saldo |

**Lo que no se podía con los 4 archivos del profesor:** K04 (el archivo de ventas solo trae
unidades netas) y K13–K14 (no hay archivo de cartera). Por eso agregamos `exportar_extra.psql`,
con dos archivos más sacados de nuestro modelo. El recaudo tampoco se puede filtrar por
vendedor, porque `recaudos_mensuales.csv` no trae vendedor: la página lo avisa.

## Decisiones durante el trabajo

- El dinero se guarda en centavos enteros, para que las sumas no pierdan centavos.
- Las gráficas son SVG hechas a mano, sin librerías, para que funcione sin internet.
- El margen % va en una gráfica aparte y no en doble eje, como dice el boceto de R5.
- La página no trae ningún valor escrito a mano: todo se calcula desde los datos embebidos.
  Lo único fijo son los valores oficiales de SQL, que solo se usan para compararse.
- La distribución se corrigió después de mirar capturas de pantalla de cada pestaña.
- **Lo que queda por revisar como grupo:** que las gráficas y los textos se entiendan.

## Cómo lo comprobamos

La pestaña **Validación** calcula los 15 indicadores en los escenarios A y B y los compara con
los valores de `04_KPI/kpi_referencia.sql`. También cuenta las filas y los totales de cada
archivo embebido. Además probamos la página en un navegador sin internet: no hubo errores ni
pedidos de red. Ver `../equivalencia_r7.md`.
