@echo off
REM Retail 360 - Etapa R5: corre los casos de prueba de los indicadores y calcula
REM los valores oficiales en SQL (los que despues deben dar Power BI y la pagina web).
REM Doble clic. Pide la contrasena de PostgreSQL. No cambia datos.
REM Requiere haber corrido antes R3 y R4.
chcp 65001 >nul
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R5 indicadores" -Salida "entregables_estudiante\04_KPI\salidas\salida_r5.txt" -Scripts "entregables_estudiante\04_KPI\casos_prueba_kpi.sql,entregables_estudiante\04_KPI\kpi_referencia.sql"
echo.
pause
