# Retail 360 · Laboratorio integrador de Inteligencia de Negocios

**Parcial – Bases de Datos II · Universidad de Manizales**
De la operación transaccional (OLTP) a la inteligencia de negocios aumentada con IA.

> Pregunta central del caso: ¿cómo puede una empresa incrementar su facturación y al mismo tiempo
> presentar deterioro del margen, problemas de disponibilidad de inventario y tensiones de recaudo?

| Dato | Valor |
|---|---|
| Integrantes | Juan Diego Ortiz · _(pendiente confirmar el resto del grupo: la guía permite máximo 3)_ |
| Motor de base de datos | PostgreSQL _(versión real: ver `entregables_estudiante/00_ARRANQUE/evidencia_entorno.txt`)_ |
| Datos | Sintéticos, semilla **360**, 12.000 pedidos, período 2024-10-01 a 2026-09-30 |
| Fuente oficial | `documentacion/Guia_Laboratorio_Retail360.docx` + scripts de `sql/` |

## Estructura del repositorio

```
├── README.md                     ← este archivo
├── README_EJECUCION.txt          ← orden de ejecución del docente
├── documentacion/                ← guía oficial y control de datos (NO modificar)
├── sql/                          ← scripts 00–13 del docente (NO modificar)
├── data/                         ← CSV sintéticos (NO modificar; verificados con SHA-256)
├── export/                       ← salidas analíticas de sql/08 (se generan en el gate R4)
├── generar_datos.py              ← generador determinista (semilla 360)
├── validar_csv.py                ← validador de los CSV
└── entregables_estudiante/       ← TODO el trabajo propio del grupo
    ├── PLAN_GATES.md             ← gates R0–R9 y su estado
    ├── DECISIONES.md             ← decisiones técnicas tomadas
    ├── 00_ARRANQUE/              ← R0: entorno, verificación e integridad del paquete
    ├── 01_OLTP/                  ← R1: modelo relacional y reglas de negocio
    ├── 02_DWH/                   ← R2: modelo dimensional
    ├── 03_ETL/                   ← R3: ETL propio, pruebas y bitácora
    ├── 04_KPI/                   ← R4–R5: retos SQL, exportaciones y contrato de KPI
    ├── 05_VISUALIZACION/         ← R6–R7: Power BI y HTML offline con IA
    ├── 06_INTERPRETACION/        ← R8–R9: hallazgos, decisiones e informe final
    └── IA/                       ← registro obligatorio de uso de IA
```

Los archivos del docente se conservan **tal cual** se entregaron: los comandos `psql` usan rutas
relativas (`data/`, `export/`) y deben ejecutarse desde la raíz de este repositorio.

## Cómo ejecutar (Windows PowerShell, desde la raíz del repositorio)

```powershell
# 1) Verificar el entorno y dejar evidencia (crea la base retail360 si no existe)
powershell -ExecutionPolicy Bypass -File entregables_estudiante\00_ARRANQUE\verificar_entorno.ps1

# 2) Ruta completa del laboratorio (ver README_EJECUCION.txt)
psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/01_esquema_oltp.sql
psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/02_cargar_datos.psql   # TRUNCATE: solo en retail360
psql -X -v ON_ERROR_STOP=1 -d retail360 -f sql/03_verificar_oltp.sql
# ... continúa en el orden indicado por cada gate
```

## Estado de los gates

| Gate | Etapa | Estado |
|---|---|---|
| R0 | Arranque, entorno e integridad del paquete | 🟡 En curso |
| R1 | OLTP – modelo relacional | ⚪ Pendiente |
| R2 | DWH – modelo dimensional | ⚪ Pendiente |
| R3 | ETL/ELT propio en PL/pgSQL | ⚪ Pendiente |
| R4 | Scripts SQL documentados (retos + exportaciones) | ⚪ Pendiente |
| R5 | Contrato de KPI y propuesta de gráficos | ⚪ Pendiente |
| R6 | Dashboard en Power BI | ⚪ Pendiente |
| R7 | HTML analítico offline generado con IA | ⚪ Pendiente |
| R8 | Interpretación de resultados | ⚪ Pendiente |
| R9 | Informe final y defensa | ⚪ Pendiente |

Detalle de cada gate y su condición de aprobación: [`entregables_estudiante/PLAN_GATES.md`](entregables_estudiante/PLAN_GATES.md).

## Uso responsable de IA

La IA se usa para **aumentar, no sustituir** el razonamiento; todo resultado se **valida con SQL**,
se **documentan los prompts y decisiones** y el grupo **mantiene la autoría**.
Registro: [`entregables_estudiante/IA/registro_ia.md`](entregables_estudiante/IA/registro_ia.md).
