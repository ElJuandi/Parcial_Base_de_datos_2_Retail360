#!/usr/bin/env python3
"""Datos sintéticos RETAIL360. Solo stdlib; sin datos personales reales.

Uso (desde carpeta raiz): python generar_datos.py --seed 360 --pedidos 12000
Genera/reescribe data/*.csv. Semilla fija para reproducibilidad.
NO simula todos los procesos reales ERP; consultar LIMITACIONES.md.
"""
import argparse, csv, random
from pathlib import Path
from datetime import date, timedelta
from decimal import Decimal, ROUND_HALF_UP
from collections import defaultdict

BASE=Path(__file__).resolve().parent
START=date(2024,10,1); END=date(2026,9,30)
CENT=Decimal('0.01'); IVA=Decimal('0.19')
def money(x): return Decimal(str(x)).quantize(CENT, rounding=ROUND_HALF_UP)
def amtstr(x): return str(money(x))
def main(seed=360, norders=12000):
 r=random.Random(seed); tables={}
 def put(table,columns,rows): tables[table]=(columns,rows)
 cities=['Manizales','Pereira','Medellín']; branches=[(i+1,f'Sucursal {cities[i]}',cities[i]) for i in range(3)]
 put('sucursal',['sucursal_id','nombre','ciudad'],branches)
 warehouses=[(1,None,'Bodega central','CENTRAL')]+[(i+2,i+1,f'Bodega {cities[i]}','LOCAL') for i in range(3)]
 put('bodega',['bodega_id','sucursal_id','nombre','tipo'],warehouses)
 names=['Adriana','Beatriz','Camilo','Daniela','Eliana','Felipe','Gabriela','Hernán','Isabel','Jorge','Karen','Leonardo','Mariana','Nicolás','Olga']
 sellers=[(i+1,1+i//5,names[i]+' '+['Ríos','Soto','López'][i%3], '2024-01-15') for i in range(15)]
 put('vendedor',['vendedor_id','sucursal_id','nombre','fecha_ingreso'],sellers)
 clients=[(i,f'Cliente sintético {i:04d}', 'EMPRESA' if i%4==0 else 'PERSONA',r.choice(cities),30 if i%4==0 else 0) for i in range(1,1501)]
 put('cliente',['cliente_id','nombre','segmento','ciudad','plazo_credito_dias'],clients)
 cats=['Portátiles','Monitores','Teclados','Mouse','Auriculares','Impresoras','Almacenamiento','Redes','Cámaras','Accesorios','Tabletas','Componentes']
 put('categoria',['categoria_id','nombre'],[(i+1,c) for i,c in enumerate(cats)])
 products=[]; product_info={}
 for i in range(1,401):
  cat=1+(i-1)%12; cost=money(r.randrange(18000,1100000,1000)); price=money(cost*Decimal(str(r.uniform(1.27,1.85))))
  products.append((i,cat,f'{cats[cat-1]} modelo {i:03d}',amtstr(cost),amtstr(price),True)); product_info[i]=(cost,price,cat)
 put('producto',['producto_id','categoria_id','nombre','costo_estandar','precio_lista','activo'],products)
 metas=[]; mid=0
 months=[date(2024+(9+j)//12, (9+j)%12+1,1) for j in range(24)]
 for month in months:
  for seller_id,branch_id,*_ in sellers:
   mid+=1; target=money(r.randrange(170000000,420000000,10000000))
   metas.append((mid,seller_id,branch_id,month.isoformat(),amtstr(target)))
 put('meta_mensual',['meta_id','vendedor_id','sucursal_id','mes','monto_meta'],metas)
 # stock por bodega/producto, nunca intencionalmente negativo; entradas de inicio
 stock=defaultdict(int); movements=[]; mov_id=0
 def mov(day,wh,prod,kind,delta,ref):
  nonlocal mov_id
  if stock[(wh,prod)]+delta<0: raise ValueError(f'stock negativo {day}/{wh}/{prod}/{delta}')
  stock[(wh,prod)]+=delta; mov_id+=1
  movements.append((mov_id,day.isoformat(),wh,prod,kind,delta,ref))
 for wh in range(1,5):
  for pid in range(1,401):
   initial=r.randint(20,105) if wh==1 else r.randint(2,70)
   mov(START,wh,pid,'APERTURA',initial,'INV_INICIAL')
 orders=[]; orderlines=[]; invoices=[]; invlines=[]; notes=[]; notelines=[]; payments=[]
 orderline_id=invoice_id=invline_id=note_id=noteline_id=pay_id=0
 soldinvoice=[]
 dayrange=(END-START).days
 # Fechas crecientes con ligera densidad variable; permite cierres mensuales
 day_indexes=sorted(r.randrange(dayrange+1) for _ in range(norders))
 for oid,day_index in enumerate(day_indexes,1):
  day=START+timedelta(days=day_index)
  branch=r.randint(1,3); wh=branch+1; seller=r.randint((branch-1)*5+1, branch*5)
  customer=r.randint(1,1500); credit=(customer%4==0)
  is_invoice=r.random()<0.835
  linecount=r.choice([2,3,3,4]); chosen=[]
  # Productos de alta demanda sobrerrepresentados (primeros 35)
  while len(chosen)<linecount:
   prod=r.randint(1,35) if r.random()<0.36 else r.randint(1,400)
   if prod not in chosen: chosen.append(prod)
  quantities={prod:r.randint(1,5) for prod in chosen}
  if not is_invoice:
   # 40% sin stock verdaderamente verificable: escoger producto con saldo menor
   low=min(range(1,401), key=lambda p: stock[(wh,p)])
   if r.random()<0.42:
    chosen=[low]+[p for p in chosen if p!=low]
    quantities[low]=stock[(wh,low)]+r.randint(1,3)
    status='PENDIENTE_STOCK'; reason='Saldo insuficiente en bodega local al solicitar pedido'
   else:
    status='CANCELADO' if r.random()<0.25 else 'PENDIENTE_CREDITO'
    reason='Cancelación comercial' if status=='CANCELADO' else 'Validación de crédito pendiente'
  else: status='FACTURADO'; reason=''
  orders.append((oid,day.isoformat(),customer,seller,branch,status,reason))
  this_lines=[]
  for pid in chosen:
   orderline_id+=1; qty=quantities[pid]
   orderlines.append((orderline_id,oid,pid,qty)); this_lines.append((orderline_id,pid,qty))
  if not is_invoice: continue
  invoice_id+=1
  due=day+timedelta(days=30 if credit else 0)
  invoices.append((invoice_id,oid,day.isoformat(),due.isoformat(),'EMITIDA'))
  total=Decimal('0'); line_records=[]
  for opd,pid,qty in this_lines:
   cost,price,_=product_info[pid]
   # descuento especialmente alto para dos vendedores (situacion de negocio)
   discount=money(Decimal(str(r.choice([0,.02,.05,.07,.10,.15,.25,.35]) if seller in (5,10) else r.choice([0,.02,.03,.05,.08,.12]))))
   gross=money(price*qty); disc=money(gross*discount); net=gross-disc; tax=money(net*IVA); total+=net+tax
   invline_id+=1
   invlines.append((invline_id,invoice_id,opd,pid,qty,amtstr(price),amtstr(cost),str(discount),str(IVA)))
   line_records.append((invline_id,pid,qty,price,cost,discount,net,tax))
   if stock[(wh,pid)]<qty:
    replenish=qty-stock[(wh,pid)]+r.randint(35,90)
    mov(day,wh,pid,'COMPRA',replenish,f'REABAST_{invoice_id}')
   mov(day,wh,pid,'VENTA',-qty,f'FACT_{invoice_id}')
  soldinvoice.append((invoice_id,day,branch,wh,customer,seller,total,line_records))
  # Actividad comercial adicional: compras para reposición y traslado ocasional
  if oid%4==0:
   prod=r.randrange(1,401); mov(day,wh,prod,'COMPRA',r.randint(10,45),f'REPO_{oid}')
  if oid%6==0:
   prod=r.randrange(1,401); source=r.choice([1,2,3,4]); dest=r.choice([w for w in (1,2,3,4) if w!=source]); qty=min(stock[(source,prod)],r.randint(1,6))
   if qty:
    mov(day,source,prod,'TRASLADO_SALIDA',-qty,f'TRAS_{oid}')
    mov(day,dest,prod,'TRASLADO_ENTRADA',qty,f'TRAS_{oid}')
  if oid%10==0:
   prod=r.randrange(1,401); mov(day,1,prod,'COMPRA',r.randint(8,36),f'COMP_CENT_{oid}')
  if oid%17==0:
   prod=r.randrange(1,401); qty=min(stock[(wh,prod)],r.randint(1,3))
   if qty: mov(day,wh,prod,'AJUSTE_SALIDA',-qty,f'AJUSTE_{oid}')
 # Notas, devoluciones y pagos dentro del horizonte; pagos <= total luego de descuentos por nota
 for fid,day,branch,wh,customer,seller,total,lines in soldinvoice:
  credited=Decimal(0)
  if r.random()<0.055 and (END-day).days>=4:
   nd=day+timedelta(days=r.randint(3,min(45,(END-day).days)))
   note_id+=1; notes.append((note_id,fid,nd.isoformat(),'Devolución parcial de producto'))
   ilid,pid,qty,price,cost,disc,net,tax=r.choice(lines)
   retqty=max(1, min(qty, r.randint(1,2))); noteline_id+=1
   notelines.append((noteline_id,note_id,ilid,retqty))
   bruto_credito=money(price*retqty); netcredit=bruto_credito-money(bruto_credito*disc); credited=netcredit+money(netcredit*IVA)
   mov(nd,wh,pid,'DEVOLUCION',retqty,f'NC_{note_id}')
  remaining=money(total-credited)
  if r.random()<0.79 and remaining>=Decimal('1.00'):
   delay=r.randint(0,75 if customer%4==0 else 3)
   paid_day=day+timedelta(days=delay)
   if paid_day<=END:
    fraction=Decimal(str(r.choice([0.25,0.50,0.65,0.85,1.0,1.0,1.0])))
    paid=money(remaining*fraction)
    if paid>0:
     pay_id+=1; payments.append((pay_id,fid,paid_day.isoformat(),amtstr(paid),r.choice(['TRANSFERENCIA','TARJETA','EFECTIVO'])))
 put('pedido',['pedido_id','fecha_pedido','cliente_id','vendedor_id','sucursal_id','estado','motivo'],orders)
 put('pedido_detalle',['pedido_detalle_id','pedido_id','producto_id','cantidad'],orderlines)
 put('factura',['factura_id','pedido_id','fecha_factura','fecha_vencimiento','estado'],invoices)
 put('factura_detalle',['factura_detalle_id','factura_id','pedido_detalle_id','producto_id','cantidad','precio_unitario','costo_unitario','descuento_pct','impuesto_pct'],invlines)
 put('nota_credito',['nota_id','factura_id','fecha_nota','motivo'],notes)
 put('nota_credito_detalle',['nota_detalle_id','nota_id','factura_detalle_id','cantidad'],notelines)
 put('pago',['pago_id','factura_id','fecha_pago','monto','medio'],payments)
 # delta ya incluye signos: fuente oficial para saldo, no fuente de ventas
 put('movimiento_inventario',['movimiento_id','fecha_movimiento','bodega_id','producto_id','tipo','cantidad_delta','referencia'],sorted(movements,key=lambda a:(a[1],a[0])))
 out=BASE/'data'; out.mkdir(exist_ok=True)
 for table,(cols,rows) in tables.items():
  with (out/(table+'.csv')).open('w',encoding='utf-8',newline='') as f:
   w=csv.writer(f); w.writerow(cols); w.writerows(rows)
  print(f'{table:24} {len(rows):>8,}')
 print(f'Conjunto sintético semilla={seed}, fecha={START}..{END}, CSV={out}')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--seed',type=int,default=360);p.add_argument('--pedidos',type=int,default=12000)
 a=p.parse_args();main(a.seed,a.pedidos)
