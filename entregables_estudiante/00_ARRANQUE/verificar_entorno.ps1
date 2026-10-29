<#
 RETAIL 360 | R0 | Verificacion del entorno y evidencia del gate de arranque.

 Que hace:
   1. Ubica psql (PATH o C:\Program Files\PostgreSQL\<version>\bin).
   2. Ubica Python (py -3.12, py o python).
   3. Ejecuta validar_csv.py (debe terminar en "Validaciones: OK").
   4. Verifica con SHA-256 que data/*.csv y la guia no fueron modificados.
   5. Se conecta a PostgreSQL, crea la base retail360 si no existe (sql/00_crear_base.sql)
      y confirma la conexion a retail360.
   6. Registra la version de Power BI Desktop.
   Todo queda en: entregables_estudiante\00_ARRANQUE\evidencia_entorno.txt

 Ejecucion (desde la RAIZ del repositorio, en PowerShell):
   powershell -ExecutionPolicy Bypass -File entregables_estudiante\00_ARRANQUE\verificar_entorno.ps1

 Parametros opcionales:
   -PgUser postgres -PgHost localhost -PgPort 5432

 Seguridad: la contrasena se pide una vez, se usa solo durante la ejecucion y se borra al final.
 No modifica datos: solo crea la base retail360 si no existe.
#>
param(
    [string]$PgUser = "postgres",
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432
)

$ErrorActionPreference = "Continue"
$raiz = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $raiz
$evidencia = Join-Path $PSScriptRoot "evidencia_entorno.txt"
"RETAIL 360 - Evidencia de entorno (gate R0)" | Out-File -FilePath $evidencia -Encoding utf8
$script:fallos = 0

function Log([string]$texto) {
    Write-Host $texto
    Add-Content -Path $evidencia -Value $texto -Encoding utf8
}
function Paso([string]$num, [string]$titulo) {
    Log ""
    Log ("=== PASO " + $num + " | " + $titulo)
}
function Fallo([string]$texto) {
    $script:fallos++
    Log ("FALLO: " + $texto)
}

Log ("Fecha: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
Log ("Equipo: " + $env:COMPUTERNAME + " | Usuario Windows: " + $env:USERNAME)
Log ("Carpeta del repositorio: " + $raiz)
Log ("Windows: " + [System.Environment]::OSVersion.VersionString)
Log ("PowerShell: " + $PSVersionTable.PSVersion.ToString())

# --------------------------------------------------------------------------
Paso "1" "Ubicar psql"
$psql = $null
$cmd = Get-Command psql -ErrorAction SilentlyContinue
if ($cmd) {
    $psql = $cmd.Source
} else {
    $candidato = Get-ChildItem "C:\Program Files\PostgreSQL\*\bin\psql.exe" -ErrorAction SilentlyContinue |
        Sort-Object { [int](($_.Directory.Parent.Name) -replace '\D', '') } -Descending |
        Select-Object -First 1
    if ($candidato) { $psql = $candidato.FullName }
}
if ($psql) {
    Log ("psql encontrado en: " + $psql)
    Log ("Version cliente: " + ((& $psql --version) -join " "))
} else {
    Fallo "No se encontro psql. Instale PostgreSQL o agregue su carpeta bin al PATH."
}

# --------------------------------------------------------------------------
Paso "2" "Ubicar Python"
$py = $null
$pyArgs = @()
foreach ($opcion in @("py -3.12", "py", "python")) {
    $partes = $opcion.Split(" ")
    $exe = $partes[0]
    $args1 = @($partes | Select-Object -Skip 1)
    if (Get-Command $exe -ErrorAction SilentlyContinue) {
        $version = (& $exe @args1 --version 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $version -match "Python") {
            $py = $exe
            $pyArgs = $args1
            Log ("Python usado: " + $opcion + " -> " + $version)
            break
        }
    }
}
if (-not $py) { Fallo "No se encontro Python 3 (py -3.12, py o python)." }

# --------------------------------------------------------------------------
Paso "3" "Validar CSV del docente (validar_csv.py)"
if ($py) {
    $salidaPy = & $py @pyArgs validar_csv.py 2>&1
    $salidaPy | ForEach-Object { Log ([string]$_) }
    if ((($salidaPy | Out-String)) -notmatch "Validaciones: OK") {
        Fallo "validar_csv.py no devolvio 'Validaciones: OK'."
    }
}

# --------------------------------------------------------------------------
Paso "4" "Integridad del paquete (SHA-256)"
$archivoHashes = Join-Path $PSScriptRoot "hashes_paquete_original.sha256"
$lineas = @(Get-Content $archivoHashes | Where-Object { $_.Trim() -ne "" })
$diferentes = 0
foreach ($linea in $lineas) {
    $partes = $linea -split "\s+", 2
    $esperado = $partes[0].ToLower()
    $ruta = $partes[1].Trim().TrimStart('*')
    if (-not (Test-Path $ruta)) {
        Log ("  FALTA      " + $ruta)
        $diferentes++
        continue
    }
    $real = (Get-FileHash -Algorithm SHA256 -Path $ruta).Hash.ToLower()
    if ($real -eq $esperado) {
        Log ("  OK         " + $ruta)
    } else {
        Log ("  DIFERENTE  " + $ruta)
        $diferentes++
    }
}
Log ("Archivos verificados: " + $lineas.Count + " | con diferencias: " + $diferentes)
if ($diferentes -gt 0) { Fallo "Hay archivos del paquete modificados o faltantes." }

# --------------------------------------------------------------------------
Paso "5" "PostgreSQL: conexion y base retail360"
if ($psql) {
    $seguro = Read-Host ("Contrasena de PostgreSQL para el usuario '" + $PgUser + "'") -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($seguro)
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    $con = @("-X", "-h", $PgHost, "-p", [string]$PgPort, "-U", $PgUser)

    $versionServidor = (& $psql @con -d postgres -tAc "SELECT version();" 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        Fallo ("No fue posible conectarse a PostgreSQL: " + $versionServidor)
    } else {
        Log ("Servidor: " + $versionServidor)
        $existe = (& $psql @con -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='retail360';" 2>&1 | Out-String).Trim()
        if ($existe -eq "1") {
            Log "La base retail360 ya existe (no se vuelve a crear)."
        } else {
            Log "La base retail360 no existe: se ejecuta sql/00_crear_base.sql"
            & $psql @con -v ON_ERROR_STOP=1 -d postgres -f sql/00_crear_base.sql 2>&1 | ForEach-Object { Log ([string]$_) }
            if ($LASTEXITCODE -ne 0) { Fallo "No se pudo crear la base retail360." }
        }
        $info = (& $psql @con -d retail360 -tAc "SELECT current_database() || ' | usuario ' || current_user || ' | version ' || current_setting('server_version') || ' | codificacion ' || pg_encoding_to_char(encoding) FROM pg_database WHERE datname = current_database();" 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0) {
            Log ("Conexion a retail360: " + $info)
        } else {
            Fallo ("No fue posible conectarse a retail360: " + $info)
        }
    }
    Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue
}

# --------------------------------------------------------------------------
Paso "6" "Power BI Desktop"
$pbi = Get-AppxPackage -Name "Microsoft.MicrosoftPowerBIDesktop" -ErrorAction SilentlyContinue
if ($pbi) {
    Log ("Power BI Desktop (Microsoft Store) version: " + $pbi.Version)
} elseif (Test-Path "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe") {
    $v = (Get-Item "C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe").VersionInfo.ProductVersion
    Log ("Power BI Desktop (instalador) version: " + $v)
} else {
    Fallo "No se encontro Power BI Desktop."
}

# --------------------------------------------------------------------------
Log ""
if ($script:fallos -eq 0) {
    Log "RESULTADO R0 (parte tecnica): OK - entorno verificado."
} else {
    Log ("RESULTADO R0 (parte tecnica): " + $script:fallos + " fallo(s). Revise los mensajes FALLO.")
}
Log ("Evidencia guardada en: " + $evidencia)
