@echo off
REM Retail 360 - Etapa R3: crea nuestro ETL, carga el modelo de analisis y corre todas las pruebas.
REM Doble clic. Pide la contrasena de PostgreSQL. No toca los datos de la operacion
REM (las pruebas que cambian algo se deshacen solas al final).
REM Requiere haber corrido antes R1 y R2.
chcp 65001 >nul
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R3 ETL" -Salida "entregables_estudiante\03_ETL\salidas\salida_r3.txt" -Scripts "entregables_estudiante\03_ETL\etl_retail360.sql,sql\05b_ejecutar_etl.sql,sql\06_validar_dwh.sql,sql\09_pruebas_aceptacion.sql,sql\12_prueba_idempotencia.sql,sql\13_ensayo_actualizacion_controlada.sql,entregables_estudiante\03_ETL\consultas_r3.sql"
echo.
pause
