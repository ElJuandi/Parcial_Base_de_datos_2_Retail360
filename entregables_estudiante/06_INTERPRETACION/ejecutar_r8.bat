@echo off
REM Retail 360 - Etapa R8: corre una consulta por cada hallazgo para comprobar los numeros.
REM Doble clic. Pide la contrasena de PostgreSQL. No cambia datos.
chcp 65001 >nul
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R8 hallazgos" -Salida "entregables_estudiante\06_INTERPRETACION\salidas\salida_r8.txt" -Scripts "entregables_estudiante\06_INTERPRETACION\consultas_r8.sql"
echo.
pause
