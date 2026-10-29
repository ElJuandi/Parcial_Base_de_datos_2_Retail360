# R0 · Arranque, entorno e integridad del paquete

**Objetivo:** dejar el repositorio listo y demostrar que el entorno puede ejecutar el laboratorio.

## Lista de verificación

- [x] Repositorio `Parcial_Base_de_datos_2_Retail360` creado y vinculado a GitHub Desktop.
- [x] Paquete del docente copiado sin modificaciones (`sql/`, `data/`, `documentacion/`, `*.py`).
- [x] Estructura de entregables, plan de gates, registro de decisiones y registro de IA.
- [x] Huellas SHA-256 de los datos originales (`hashes_paquete_original.sha256`).
- [ ] Ejecutar `verificar_entorno.ps1` en el equipo y subir `evidencia_entorno.txt`.
- [ ] `validar_csv.py` devuelve **Validaciones: OK**.
- [ ] Base `retail360` creada y conexión confirmada.
- [ ] Versiones registradas: PostgreSQL, Python, Power BI Desktop.
- [ ] Conformación del grupo confirmada (máximo 3 integrantes según la guía).

## Cómo ejecutar

Desde la **raíz** del repositorio, en PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File entregables_estudiante\00_ARRANQUE\verificar_entorno.ps1
```

El script pide la contraseña de PostgreSQL una sola vez (no la guarda) y genera
`evidencia_entorno.txt` en esta carpeta.

## Condición de aprobación

`RESULTADO R0 (parte tecnica): OK` en la evidencia + grupo confirmado.
