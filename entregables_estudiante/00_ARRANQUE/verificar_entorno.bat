@echo off
REM Revisa que el computador este listo para el laboratorio Retail 360 (etapa R0).
REM Doble clic sobre este archivo. Pedira la contrasena de PostgreSQL.
cd /d "%~dp0..\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "entregables_estudiante\00_ARRANQUE\verificar_entorno.ps1"
echo.
echo Resultado guardado en entregables_estudiante\00_ARRANQUE\evidencia_entorno.txt
pause
