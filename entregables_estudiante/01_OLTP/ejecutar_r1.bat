@echo off
REM Retail 360 - Etapa R1: crea las tablas de la operacion, carga los datos y los revisa.
REM Doble clic. Pide la contrasena de PostgreSQL. OJO: el script 02 borra y vuelve a cargar las tablas de retail360.
chcp 65001 >nul
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R1 OLTP" -Salida "entregables_estudiante\01_OLTP\salidas\salida_r1.txt" -Scripts "sql\01_esquema_oltp.sql,sql\02_cargar_datos.psql,sql\03_verificar_oltp.sql,entregables_estudiante\01_OLTP\consultas_r1.sql"
echo.
pause
