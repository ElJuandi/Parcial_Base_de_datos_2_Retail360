@echo off
REM Retail 360 - Etapa R4: crea las vistas de analisis y de cartera, exporta los 4 CSV,
REM resuelve los 12 retos SQL y revisa que los archivos cuadren.
REM Doble clic. Pide la contrasena de PostgreSQL. No cambia datos; solo escribe los CSV en export\.
REM Requiere haber corrido antes R1, R2 y R3.
chcp 65001 >nul
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R4 consultas" -Salida "entregables_estudiante\04_KPI\salidas\salida_r4.txt" -Scripts "sql\07_vistas_analiticas.sql,sql\10_cartera_corte.sql,sql\08_exportar_analitica.psql,entregables_estudiante\04_KPI\retos_r4.sql,entregables_estudiante\04_KPI\validar_exportes.sql"
echo.
pause
