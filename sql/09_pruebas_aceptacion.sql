-- RETAIL 360 | 09 | PRUEBAS EJECUTABLES de aceptación del DWH (fallan con RAISE EXCEPTION).
-- PRERREQUISITOS: 01-07 ejecutados; data/ valida; facturas EMITIDAS.
-- EJECUCION: psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/09_pruebas_aceptacion.sql
-- Se calcula el neto de origen independientemente del ETL; no confiar solo en conteos.
DO $$
DECLARE
    esperadas_ventas bigint;
    esperadas_inv bigint;
    esperadas_metas bigint;
    esperadas_pagos bigint;
    neto_oltp numeric(20,2);
    neto_dwh numeric(20,2);
    v_venta numeric(20,2);
    v_nota numeric(20,2);
    inv_negativos bigint;
    filas_metas_duplicadas bigint;
BEGIN
    SELECT count(*) INTO esperadas_ventas FROM oltp.factura_detalle fd
      JOIN oltp.factura f ON f.factura_id=fd.factura_id WHERE f.estado='EMITIDA';
    esperadas_ventas := esperadas_ventas +
      (SELECT count(*) FROM oltp.nota_credito_detalle nd
       JOIN oltp.nota_credito nc ON nc.nota_id=nd.nota_id
       JOIN oltp.factura f ON f.factura_id=nc.factura_id WHERE f.estado='EMITIDA');
    SELECT count(*) INTO esperadas_inv FROM oltp.movimiento_inventario;
    SELECT count(*) INTO esperadas_metas FROM oltp.meta_mensual;
    SELECT count(*) INTO esperadas_pagos FROM oltp.pago p
      JOIN oltp.factura f ON f.factura_id=p.factura_id WHERE f.estado='EMITIDA';
    IF (SELECT count(*) FROM dwh.fact_venta) <> esperadas_ventas THEN
        RAISE EXCEPTION 'Conteo de fact_venta inconsistente: esperado %', esperadas_ventas;
    END IF;
    IF (SELECT count(*) FROM dwh.fact_movimiento_inventario) <> esperadas_inv THEN
        RAISE EXCEPTION 'Conteo de inventarios inconsistente: esperado %', esperadas_inv;
    END IF;
    IF (SELECT count(*) FROM dwh.fact_meta) <> esperadas_metas THEN
        RAISE EXCEPTION 'Conteo de metas inconsistente: esperado %', esperadas_metas;
    END IF;
    IF (SELECT count(*) FROM dwh.fact_recaudo) <> esperadas_pagos THEN
        RAISE EXCEPTION 'Conteo de recaudos inconsistente: esperado %', esperadas_pagos;
    END IF;

    SELECT COALESCE(SUM(
      ROUND(fd.precio_unitario*fd.cantidad,2)
      -ROUND(ROUND(fd.precio_unitario*fd.cantidad,2)*fd.descuento_pct,2)
    ),0)::numeric(20,2) INTO v_venta
    FROM oltp.factura_detalle fd
    JOIN oltp.factura f ON f.factura_id=fd.factura_id WHERE f.estado='EMITIDA';

    SELECT COALESCE(SUM(
      ROUND(fd.precio_unitario*nd.cantidad,2)
      -ROUND(ROUND(fd.precio_unitario*nd.cantidad,2)*fd.descuento_pct,2)
    ),0)::numeric(20,2) INTO v_nota
    FROM oltp.nota_credito_detalle nd
    JOIN oltp.nota_credito nc ON nc.nota_id=nd.nota_id
    JOIN oltp.factura f ON f.factura_id=nc.factura_id
    JOIN oltp.factura_detalle fd ON fd.factura_detalle_id=nd.factura_detalle_id
    WHERE f.estado='EMITIDA';

    neto_oltp := v_venta - v_nota;
    SELECT COALESCE(SUM(venta_neta),0) INTO neto_dwh FROM dwh.fact_venta;
    IF neto_oltp <> neto_dwh THEN
        RAISE EXCEPTION 'Diferencia neto OLTP=% DWH=% diferencia=%',
              neto_oltp, neto_dwh, neto_oltp-neto_dwh;
    END IF;

    SELECT count(*) INTO filas_metas_duplicadas FROM (
        SELECT vendedor_key, sucursal_key, mes_fecha_key
        FROM dwh.fact_meta GROUP BY 1,2,3 HAVING count(*)>1
    ) m;
    IF filas_metas_duplicadas <> 0 THEN
        RAISE EXCEPTION 'Metas repetidas por granularidad: %', filas_metas_duplicadas;
    END IF;
    SELECT count(*) INTO inv_negativos FROM (
        SELECT bodega_key, producto_key, SUM(cantidad_delta) saldo
        FROM dwh.fact_movimiento_inventario GROUP BY 1,2 HAVING SUM(cantidad_delta)<0
    ) x;
    IF inv_negativos <> 0 THEN
        RAISE EXCEPTION 'Saldos finales de inventario negativos: %', inv_negativos;
    END IF;
    RAISE NOTICE 'ACEPTACION OK | hechos venta=% inventario=% metas=% recaudos=% | neto=%',
                 esperadas_ventas, esperadas_inv, esperadas_metas, esperadas_pagos, neto_dwh;
END $$;
