@echo off
REM Retail 360 - Etapa R7: exporta los CSV para la pagina web y arma el tablero sin internet.
REM Doble clic. Pide la contrasena de PostgreSQL. No cambia datos.
REM Requiere haber corrido antes R1 a R4 (las vistas de los scripts 07 y 10 ya deben existir).
chcp 65001 >nul
cd /d "%~dp0..\..\.."
set SALIDA=entregables_estudiante\05_VISUALIZACION\web\salidas\salida_r7.txt
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\herramientas\correr_sql.ps1" -Titulo "Retail 360 - R7 tablero web" -Salida "%SALIDA%" -Scripts "sql\08_exportar_analitica.psql,entregables_estudiante\05_VISUALIZACION\web\exportar_extra.psql"
echo.
echo ===== Armando la pagina con generar_tablero.py =====
echo.>> "%SALIDA%"
echo ===== generar_tablero.py =====>> "%SALIDA%"
set PYTHONIOENCODING=utf-8
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 "entregables_estudiante\05_VISUALIZACION\web\generar_tablero.py" >> "%SALIDA%" 2>&1
) else (
  python "entregables_estudiante\05_VISUALIZACION\web\generar_tablero.py" >> "%SALIDA%" 2>&1
)
type "%SALIDA%" | findstr /C:"RESULTADO" /C:"FALTA" /C:"Error" /C:"Traceback"
echo.
echo Abra entregables_estudiante\05_VISUALIZACION\web\tablero_retail360.html con doble clic y revise la pestana Validacion.
pause
