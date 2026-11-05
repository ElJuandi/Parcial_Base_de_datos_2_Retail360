@echo off
REM Retail 360 - Etapa R2: crea el modelo de analisis (vacio), le hace nuestros ajustes y corre las revisiones.
REM Doble clic. Pide la contrasena de PostgreSQL. No borra datos.
chcp 65001 >nul
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R2 modelo de analisis" -Salida "entregables_estudiante\02_DWH\salidas\salida_r2.txt" -Scripts "sql\04_esquema_dwh.sql,entregables_estudiante\02_DWH\ajustes_dwh_grupo.sql,entregables_estudiante\02_DWH\consultas_r2.sql,entregables_estudiante\02_DWH\demo_meta_duplicada.sql"
echo.
pause
