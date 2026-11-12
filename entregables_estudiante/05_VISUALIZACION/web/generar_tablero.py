"""Retail 360 | R7 | Arma la página web del tablero (un solo HTML que funciona sin internet).

Lee los 6 CSV de la carpeta export/ (los 4 del script 08 del profesor y los 2 de exportar_extra.psql),
los mete dentro de plantilla_tablero.html y escribe tablero_retail360.html.
No usa internet ni librerías externas: solo Python estándar.

Uso, desde la raíz del repositorio:
    py entregables_estudiante/05_VISUALIZACION/web/generar_tablero.py
"""
import csv
import json
import sys
from datetime import datetime
from decimal import Decimal
from pathlib import Path

AQUI = Path(__file__).resolve().parent
RAIZ = AQUI.parents[2]
EXPORT = RAIZ / "export"
PLANTILLA = AQUI / "plantilla_tablero.html"
SALIDA = AQUI / "tablero_retail360.html"

# Valores oficiales de 04_KPI/kpi_referencia.sql (R5). Porcentajes x 100. La página se compara contra esto.
REFERENCIA = {
    "A": {"K01": 77065123983.86, "K02": 90095, "K03": 5.99, "K04": 0.81, "K05": 24544503983.86, "K06": 31.85,
          "K07": 103770000000.00, "K08": 74.27, "K09": 20.28, "K10": 122341, "K11": 7, "K12": 54081947963.55,
          "K13": 37625549579.13, "K14": 97.57, "K15": 91707497542.68},
    "B": {"K01": 946766660.41, "K02": 1128, "K03": 6.64, "K04": 1.31, "K05": 289928660.41, "K06": 30.62,
          "K07": 1360000000.00, "K08": 69.62, "K09": 40.00, "K10": 23598, "K11": 2, "K12": 695338048.03,
          "K13": 12226333944.19, "K14": 97.50, "K15": 1126652325.93},
}
# Filas y totales esperados de cada archivo (R4: validar_exportes.sql; R7: exportar_extra.psql).
ESPERADO = {
    "ventas_mensuales.csv": (4316, "77065123983.86"),
    "metas_mensuales.csv": (360, "103770000000.00"),
    "recaudos_mensuales.csv": (7583, "54081947963.55"),
    "stock_corte.csv": (1600, "122341"),
    "unidades_mensuales.csv": (4316, "90834 - 739"),
    "cartera_corte.csv": (10019, "37625549579.13"),
}


def leer(nombre):
    ruta = EXPORT / nombre
    if not ruta.exists():
        sys.exit(f"FALTA {ruta}. Corra primero ejecutar_r7.bat (exporta los CSV).")
    with open(ruta, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def centavos(texto):
    """Dinero exacto en centavos (entero), para que las sumas no pierdan centavos."""
    return int((Decimal(texto or "0") * 100).to_integral_value())


def main():
    ventas, metas, recaudos = leer("ventas_mensuales.csv"), leer("metas_mensuales.csv"), leer("recaudos_mensuales.csv")
    stock, unidades, cartera = leer("stock_corte.csv"), leer("unidades_mensuales.csv"), leer("cartera_corte.csv")

    categorias = sorted({r["categoria"] for r in ventas} | {r["categoria"] for r in stock})
    cat = {c: i for i, c in enumerate(categorias)}
    sucursales, vendedores = {}, {}
    for r in ventas + metas:
        sucursales[int(r["sucursal_id"])] = r["sucursal"]
        vendedores[int(r["vendedor_id"])] = r["vendedor"]
    bodegas, productos, prod_idx = {}, [], {}
    for r in stock:
        bodegas[int(r["bodega_id"])] = [r["bodega"], int(r["sucursal_id"]) if r["sucursal_id"] else None]
        if r["producto"] not in prod_idx:
            prod_idx[r["producto"]] = len(productos)
            productos.append(r["producto"])
    segmentos = sorted({r["segmento"] for r in cartera})
    seg = {s: i for i, s in enumerate(segmentos)}

    datos = {
        "generado": datetime.now().strftime("%d/%m/%Y %H:%M"),
        "meses": sorted({int(r["periodo_yyyymm"]) for r in ventas}),
        "categorias": categorias, "sucursales": sucursales, "vendedores": vendedores,
        "bodegas": bodegas, "productos": productos, "segmentos": segmentos,
        # [mes, sucursal, vendedor, categoria, unidades_net, venta_neta, costo, margen, descuentos, neto_con_iva]
        "ventas": [[int(r["periodo_yyyymm"]), int(r["sucursal_id"]), int(r["vendedor_id"]), cat[r["categoria"]],
                    int(r["unidades_net"]), centavos(r["venta_neta"]), centavos(r["costo_venta"]),
                    centavos(r["margen_bruto"]), centavos(r["descuentos"]), centavos(r["neto_con_impuestos"])] for r in ventas],
        # [mes, sucursal, vendedor, categoria, facturadas, devueltas]
        "unidades": [[int(r["periodo_yyyymm"]), int(r["sucursal_id"]), int(r["vendedor_id"]), cat[r["categoria"]],
                      int(r["unidades_facturadas"]), int(r["unidades_devueltas"])] for r in unidades],
        # [mes, sucursal, vendedor, meta]
        "metas": [[int(r["periodo_yyyymm"]), int(r["sucursal_id"]), int(r["vendedor_id"]), centavos(r["meta_ventas"])] for r in metas],
        # [mes, sucursal, monto]
        "recaudos": [[int(r["periodo_yyyymm"]), int(r["sucursal_id"]), centavos(r["monto_recaudado"])] for r in recaudos],
        # [bodega, sucursal o null, producto, categoria, existencia]
        "stock": [[int(r["bodega_id"]), int(r["sucursal_id"]) if r["sucursal_id"] else None, prod_idx[r["producto"]],
                   cat[r["categoria"]], int(r["existencia_a_corte"])] for r in stock],
        # [sucursal, vendedor, segmento, saldo, vencida, dias_desde_vencimiento]
        "cartera": [[int(r["sucursal_id"]), int(r["vendedor_id"]), seg[r["segmento"]], centavos(r["saldo"]),
                     centavos(r["cartera_vencida"]), int(r["dias_desde_vencimiento"])] for r in cartera],
        "referencia": REFERENCIA,
    }

    def total(dinero):
        return f"{Decimal(dinero) / 100:.2f}"

    datos["control"] = [
        ["ventas_mensuales.csv", len(ventas), ESPERADO["ventas_mensuales.csv"][0], total(sum(r[5] for r in datos["ventas"])), ESPERADO["ventas_mensuales.csv"][1]],
        ["metas_mensuales.csv", len(metas), ESPERADO["metas_mensuales.csv"][0], total(sum(r[3] for r in datos["metas"])), ESPERADO["metas_mensuales.csv"][1]],
        ["recaudos_mensuales.csv", len(recaudos), ESPERADO["recaudos_mensuales.csv"][0], total(sum(r[2] for r in datos["recaudos"])), ESPERADO["recaudos_mensuales.csv"][1]],
        ["stock_corte.csv", len(stock), ESPERADO["stock_corte.csv"][0], str(sum(r[4] for r in datos["stock"])), ESPERADO["stock_corte.csv"][1]],
        ["unidades_mensuales.csv", len(unidades), ESPERADO["unidades_mensuales.csv"][0],
         f"{sum(r[4] for r in datos['unidades'])} - {sum(r[5] for r in datos['unidades'])}", ESPERADO["unidades_mensuales.csv"][1]],
        ["cartera_corte.csv", len(cartera), ESPERADO["cartera_corte.csv"][0], total(sum(r[3] for r in datos["cartera"])), ESPERADO["cartera_corte.csv"][1]],
    ]

    html = PLANTILLA.read_text(encoding="utf-8")
    if "/*__DATOS__*/null" not in html:
        sys.exit("La plantilla no tiene el marcador /*__DATOS__*/null")
    texto = json.dumps(datos, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    SALIDA.write_text(html.replace("/*__DATOS__*/null", texto), encoding="utf-8")

    bien = all(c[1] == c[2] and c[3] == c[4] for c in datos["control"])
    for c in datos["control"]:
        print(f"{c[0]:<24} filas {c[1]:>6} (esperado {c[2]:>6})  total {c[3]:>18} (esperado {c[4]})")
    print(f"Página escrita en {SALIDA} ({SALIDA.stat().st_size / 1024:.0f} KB)")
    print("RESULTADO R7: OK - archivos completos" if bien else "RESULTADO R7: REVISAR - algún archivo no cuadra")


if __name__ == "__main__":
    main()
