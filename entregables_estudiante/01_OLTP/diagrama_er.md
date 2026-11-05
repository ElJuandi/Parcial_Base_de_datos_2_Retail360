# Diagrama entidad-relación (OLTP)

Así está organizada la base de la operación diaria de la tienda: 15 tablas.
La imagen `diagrama_er.png` es el mismo diagrama.

```mermaid
erDiagram
    SUCURSAL ||--o{ BODEGA : "tiene (las locales)"
    SUCURSAL ||--o{ VENDEDOR : "trabaja en"
    SUCURSAL ||--o{ PEDIDO : "recibe"
    SUCURSAL ||--o{ META_MENSUAL : "tiene"
    VENDEDOR ||--o{ META_MENSUAL : "tiene"
    VENDEDOR ||--o{ PEDIDO : "toma"
    CLIENTE ||--o{ PEDIDO : "hace"
    CATEGORIA ||--o{ PRODUCTO : "agrupa"
    PEDIDO ||--|{ PEDIDO_DETALLE : "lleva"
    PRODUCTO ||--o{ PEDIDO_DETALLE : "se pide en"
    PEDIDO ||--o| FACTURA : "se factura en"
    FACTURA ||--|{ FACTURA_DETALLE : "lleva"
    PEDIDO_DETALLE ||--o| FACTURA_DETALLE : "se factura como"
    PRODUCTO ||--o{ FACTURA_DETALLE : "se vende en"
    FACTURA ||--o{ NOTA_CREDITO : "puede tener"
    NOTA_CREDITO ||--|{ NOTA_CREDITO_DETALLE : "lleva"
    FACTURA_DETALLE ||--o{ NOTA_CREDITO_DETALLE : "se devuelve en"
    FACTURA ||--o{ PAGO : "se paga con"
    BODEGA ||--o{ MOVIMIENTO_INVENTARIO : "registra"
    PRODUCTO ||--o{ MOVIMIENTO_INVENTARIO : "se mueve en"

    SUCURSAL {
        int sucursal_id PK
        text nombre
        text ciudad
    }
    BODEGA {
        int bodega_id PK
        int sucursal_id FK "vacío en la central"
        text nombre
        text tipo "CENTRAL o LOCAL"
    }
    VENDEDOR {
        int vendedor_id PK
        int sucursal_id FK
        text nombre
        date fecha_ingreso
    }
    CLIENTE {
        int cliente_id PK
        text nombre
        text segmento "PERSONA o EMPRESA"
        text ciudad
        int plazo_credito_dias
    }
    CATEGORIA {
        int categoria_id PK
        text nombre
    }
    PRODUCTO {
        int producto_id PK
        int categoria_id FK
        text nombre
        numeric costo_estandar
        numeric precio_lista
    }
    META_MENSUAL {
        int meta_id PK
        int vendedor_id FK
        int sucursal_id FK
        date mes
        numeric monto_meta
    }
    PEDIDO {
        int pedido_id PK
        date fecha_pedido
        int cliente_id FK
        int vendedor_id FK
        int sucursal_id FK
        text estado
        text motivo
    }
    PEDIDO_DETALLE {
        int pedido_detalle_id PK
        int pedido_id FK
        int producto_id FK
        int cantidad
    }
    FACTURA {
        int factura_id PK
        int pedido_id FK "uno a uno con pedido"
        date fecha_factura
        date fecha_vencimiento
        text estado
    }
    FACTURA_DETALLE {
        int factura_detalle_id PK
        int factura_id FK
        int pedido_detalle_id FK
        int producto_id FK
        int cantidad
        numeric precio_unitario
        numeric costo_unitario
        numeric descuento_pct
        numeric impuesto_pct
    }
    NOTA_CREDITO {
        int nota_id PK
        int factura_id FK
        date fecha_nota
        text motivo
    }
    NOTA_CREDITO_DETALLE {
        int nota_detalle_id PK
        int nota_id FK
        int factura_detalle_id FK
        int cantidad
    }
    PAGO {
        int pago_id PK
        int factura_id FK
        date fecha_pago
        numeric monto
        text medio
    }
    MOVIMIENTO_INVENTARIO {
        bigint movimiento_id PK
        date fecha_movimiento
        int bodega_id FK
        int producto_id FK
        text tipo
        int cantidad_delta "positivo entra, negativo sale"
    }
```

## Cómo leerlo

- Un **pedido** es lo que el cliente pide. Si se aprueba, se convierte en **una factura**.
- La **factura** tiene varias líneas (productos). Si el cliente devuelve algo, se hace una
  **nota crédito** que apunta a la línea devuelta. La factura original no se borra.
- Los **pagos** van contra la factura y pueden ser parciales.
- El **inventario** no se guarda como un número fijo: se calcula sumando todos los movimientos
  (entradas en positivo, salidas en negativo) de cada producto en cada bodega.
- Las **metas** son por vendedor, sucursal y mes.

Comparado con la infografía del curso, agregamos las tablas `sucursal`, `nota_credito` y
`nota_credito_detalle`, que están en los datos reales pero no salen en la imagen.
