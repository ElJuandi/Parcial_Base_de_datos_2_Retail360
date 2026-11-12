-- Retail 360 | R8 | Una consulta por hallazgo, para que cualquiera pueda comprobarlo.
-- Solo consulta. Necesita R3 cargado y las vistas de los scripts 07 y 10 (R4).

-- H1. Nadie llega a la meta: cumplimiento total y meses en que sí se cumplió.
WITH v AS (SELECT vendedor_key, sucursal_key, fecha_key / 100 AS periodo, sum(venta_neta) AS venta
           FROM dwh.fact_venta GROUP BY 1, 2, 3),
     c AS (SELECT m.monto_meta, coalesce(v.venta, 0) AS venta, m.vendedor_key
           FROM dwh.fact_meta m LEFT JOIN v ON v.vendedor_key = m.vendedor_key
            AND v.sucursal_key = m.sucursal_key AND v.periodo = m.mes_fecha_key / 100)
SELECT round(100 * sum(venta) / sum(monto_meta), 1) AS cumplimiento_pct,
       count(*) AS metas_mes_vendedor,
       count(*) FILTER (WHERE venta >= monto_meta) AS metas_cumplidas,
       (SELECT count(*) FROM (SELECT vendedor_key FROM c GROUP BY 1 HAVING sum(venta) >= sum(monto_meta)) x) AS vendedores_sobre_100
FROM c;

-- H2. Los dos vendedores que más descuento dan, contra el resto.
SELECT CASE WHEN d.vendedor_id IN (5, 10) THEN d.nombre ELSE 'Los otros 13' END AS grupo,
       round(100 * sum(f.descuento) / sum(f.valor_bruto), 1) AS descuento_pct,
       round(100 * sum(f.venta_neta - f.costo_venta) / sum(f.venta_neta), 1) AS margen_pct,
       sum(f.venta_neta) AS venta_neta
FROM dwh.fact_venta f JOIN dwh.dim_vendedor d ON d.vendedor_key = f.vendedor_key
GROUP BY 1 ORDER BY 2 DESC;

-- H3. Pedidos frenados por stock que la bodega central sí podía cubrir.
WITH l AS (
  SELECT p.pedido_id, pd.producto_id, pd.cantidad, p.fecha_pedido, bl.bodega_id
  FROM oltp.pedido p JOIN oltp.pedido_detalle pd ON pd.pedido_id = p.pedido_id
  JOIN oltp.bodega bl ON bl.sucursal_id = p.sucursal_id
  WHERE p.estado = 'PENDIENTE_STOCK'
), s AS (
  SELECT l.*,
    (SELECT coalesce(sum(cantidad_delta), 0) FROM oltp.movimiento_inventario m
      WHERE m.bodega_id = l.bodega_id AND m.producto_id = l.producto_id AND m.fecha_movimiento <= l.fecha_pedido) AS local,
    (SELECT coalesce(sum(cantidad_delta), 0) FROM oltp.movimiento_inventario m
      JOIN oltp.bodega b ON b.bodega_id = m.bodega_id AND b.tipo = 'CENTRAL'
      WHERE m.producto_id = l.producto_id AND m.fecha_movimiento <= l.fecha_pedido) AS central
  FROM l
)
SELECT count(DISTINCT pedido_id) AS pedidos_pendientes,
       count(*) FILTER (WHERE local < cantidad) AS lineas_sin_stock_local,
       count(*) FILTER (WHERE local < cantidad AND central >= cantidad) AS la_central_si_tenia,
       (SELECT round(100.0 * sum(existencia_a_corte) FILTER (WHERE sucursal_id IS NULL) / sum(existencia_a_corte), 1)
          FROM dwh.vw_stock_corte) AS pct_inventario_en_central
FROM s;

-- H4. Cartera: cuánto se debe, cuánto está vencido y quién lo debe.
SELECT c.segmento, c.plazo_credito_dias,
       sum(v.saldo) AS saldo, sum(v.cartera_vencida) AS vencida,
       round(100 * sum(v.saldo) FILTER (WHERE v.dias_desde_vencimiento > 180) / sum(v.saldo), 1) AS pct_mas_de_180_dias
FROM dwh.vw_cartera_corte v JOIN dwh.dim_cliente c ON c.cliente_id = v.cliente_id
GROUP BY ROLLUP ((c.segmento, c.plazo_credito_dias)) ORDER BY 1;

SELECT round(100 * (SELECT sum(monto_recaudado) FROM dwh.fact_recaudo)
             / (SELECT sum(valor_facturado_con_impuesto) FROM dwh.fact_venta), 1) AS recaudado_sobre_facturado_pct;

-- H5. Redes deja menos margen sin dar más descuento.
SELECT p.categoria,
       round(100 * sum(f.descuento) / sum(f.valor_bruto), 2) AS descuento_pct,
       round(100 * sum(f.venta_neta - f.costo_venta) / sum(f.venta_neta), 1) AS margen_pct,
       round(100 * sum(f.costo_venta) / sum(f.valor_bruto), 1) AS costo_sobre_precio_pct
FROM dwh.fact_venta f JOIN dwh.dim_producto p ON p.producto_key = f.producto_key
GROUP BY p.categoria ORDER BY margen_pct;

-- Extra: ¿el margen viene bajando? (la pregunta del caso). Margen % por semestre.
SELECT f.anio || CASE WHEN f.mes_num <= 6 THEN '-S1' ELSE '-S2' END AS semestre,
       sum(v.venta_neta) AS venta_neta,
       round(100 * sum(v.venta_neta - v.costo_venta) / sum(v.venta_neta), 2) AS margen_pct
FROM dwh.fact_venta v JOIN dwh.dim_fecha f ON f.fecha_key = v.fecha_key
GROUP BY 1 ORDER BY 1;
