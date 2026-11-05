# Acuerdo del grupo sobre los indicadores

La regla de R5 es que **todo el grupo aprueba el catálogo antes de abrir Power BI**. Cada
integrante revisa `catalogo_kpi.md`, `casos_prueba_kpi.md` y `wireframes.md`, y llena su fila.
Si alguien no está de acuerdo con algo, lo escribe en comentarios y lo discutimos antes de
seguir. Después de aprobado, ninguna fórmula se cambia sin volver a pasar por aquí.

| Integrante | Revisó el catálogo | Revisó los casos de prueba | Revisó los bocetos | Aprueba | Fecha | Comentarios |
|---|---|---|---|---|---|---|
| Juan Diego Ortiz | si | si | si | si | 04 noviembre 2026 | nada |
| Adrian Daniel Argotte | si | si | si | si | 04 noviembre 2026 | nada |
| Miguel Andrés Pava | si | si | si | si | 04 noviembre 2026 | nada |
| Jerónimo Soto | si | si | si | si | 04 noviembre 2026 | nada |
| David González | si | si | si | si | 04 noviembre 2026 | muy bonito |

## Decisiones que tomamos al definir los indicadores

1. Ventas y margen van sin IVA. Facturación, recaudo y cartera van con IVA.
2. Las notas crédito restan en su propia fecha, no en la fecha de la factura.
3. La tasa de devolución se divide por las unidades facturadas, no por las netas.
4. La meta solo se filtra por mes, sucursal y vendedor.
5. Inventario y cartera son fotos al 30/09/2026.
6. No mostramos utilidad neta ni rotación valorizada porque el caso no trae esos datos.
7. Los valores oficiales son los de `kpi_referencia.sql`. Power BI y la página web deben dar
   exactamente eso con los mismos filtros (escenarios A y B).
