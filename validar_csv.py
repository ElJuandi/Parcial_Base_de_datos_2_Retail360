#!/usr/bin/env python3
"""Controles de consistencia sobre los CSV del caso Retail 360 (solo biblioteca estandar).
Ejecutar: python validar_csv.py. Retorna exit 1 ante fallos materiales.
"""
import csv, sys
from pathlib import Path
from collections import Counter,defaultdict
from decimal import Decimal, ROUND_HALF_UP
from datetime import date
BASE=Path(__file__).resolve().parent/'data'
def rows(name):
 with (BASE/(name+'.csv')).open(encoding='utf-8',newline='') as f:
  return list(csv.DictReader(f))
def money(x):return x.quantize(Decimal('.01'),rounding=ROUND_HALF_UP)
errors=[]
def check(condition,message):
 if not condition: errors.append(message)
orders=rows('pedido'); lines=rows('pedido_detalle'); invoices=rows('factura'); invlines=rows('factura_detalle')
notes=rows('nota_credito'); notelines=rows('nota_credito_detalle'); pays=rows('pago'); moves=rows('movimiento_inventario'); metas=rows('meta_mensual')
by_order={int(x['pedido_id']):x for x in orders}
by_order_line={int(x['pedido_detalle_id']):x for x in lines}
by_inv={int(x['factura_id']):x for x in invoices}
by_invoice_line={int(x['factura_detalle_id']):x for x in invlines}
by_note={int(x['nota_id']):x for x in notes}
check(len(by_order)==len(orders),'pedido_id duplicado')
check(len(by_inv)==len(invoices),'factura_id duplicado')
check(len(set((m['vendedor_id'],m['sucursal_id'],m['mes']) for m in metas))==len(metas),'meta duplicada por grano')
for x in invoices:
 order=by_order[int(x['pedido_id'])]
 check(order['estado']=='FACTURADO','factura de pedido no facturado')
 check(x['fecha_factura']>=order['fecha_pedido'],'factura anterior a pedido')
for x in invlines:
 inv=by_inv[int(x['factura_id'])]; pl=by_order_line[int(x['pedido_detalle_id'])]
 check(int(pl['pedido_id'])==int(inv['pedido_id']),'factura_detalle vinculado a otro pedido')
 check(pl['producto_id']==x['producto_id'],'factura_detalle producto divergente')
 check(pl['cantidad']==x['cantidad'],'cantidad facturada difiere de solicitada')
retd=defaultdict(int); paid=defaultdict(lambda:Decimal('0')); totals=defaultdict(lambda:Decimal('0')); cred=defaultdict(lambda:Decimal('0'))
for x in invlines:
 price=Decimal(x['precio_unitario']);q=int(x['cantidad']);p=Decimal(x['descuento_pct']);tax=Decimal(x['impuesto_pct'])
 bruto=money(price*q); net=bruto-money(bruto*p)
 totals[int(x['factura_id'])]+=net+money(net*tax)
for x in notelines:
 note=by_note[int(x['nota_id'])];fd=by_invoice_line[int(x['factura_detalle_id'])]
 check(note['factura_id']==fd['factura_id'],'nota referencia otra factura')
 q=int(x['cantidad']); retd[int(x['factura_detalle_id'])]+=q
 price=Decimal(fd['precio_unitario']);p=Decimal(fd['descuento_pct']);tax=Decimal(fd['impuesto_pct'])
 bruto=money(price*q);net=bruto-money(bruto*p)
 cred[int(note['factura_id'])]+=net+money(net*tax)
 check(note['fecha_nota']>=by_inv[int(note['factura_id'])]['fecha_factura'],'NC anterior a factura')
for ilid,q in retd.items():check(q<=int(by_invoice_line[ilid]['cantidad']),'devolucion supera unidades facturadas')
for x in pays:
 fid=int(x['factura_id']);paid[fid]+=Decimal(x['monto'])
 check(x['fecha_pago']>=by_inv[fid]['fecha_factura'],'pago anterior a factura')
for fid,p in paid.items():check(p <= totals[fid]-cred[fid],'recaudo excede neto facturado tras NC')
stock=defaultdict(int)
for x in sorted(moves,key=lambda a:(a['fecha_movimiento'],int(a['movimiento_id']))):
 key=(x['bodega_id'],x['producto_id']);stock[key]+=int(x['cantidad_delta'])
 check(stock[key]>=0, 'stock negativo en recorrido cronológico '+str(key)+' fecha '+x['fecha_movimiento'])
for oid,o in by_order.items():
 if o['estado']=='PENDIENTE_STOCK':check(bool(o['motivo']),'pedido pendiente stock sin motivo')
print('Verificacion CSV Retail360')
for name,n in [('pedidos',len(orders)),('facturas',len(invoices)),('lineas_factura',len(invlines)),('notas_credito',len(notes)),('movimientos_inventario',len(moves)),('metas',len(metas))]:print(f'{name:24}{n:>8,}')
print('Ventas brutas con impuesto, sin NC:',money(sum(totals.values())))
print('Notas credito con impuesto:',money(sum(cred.values())))
print('Recaudos:',money(sum(paid.values())))
print('Validaciones:', 'OK' if not errors else f'{len(errors)} observaciones')
for e in errors[:12]:print('ERROR:',e)
sys.exit(1 if errors else 0)
