#*===============================================================================
#* Instalación de Dependencias
#*===============================================================================

$SQLModule = Get-InstalledModule -Name "SqlServer"
if ($SQLModule.Name -eq "SqlServer") {
    Write-Output "SqlServer ya esta instalado"
}
else {
    Write-Output "Instalando Modulo de SqlServer, no deberia tardar mucho..."
    Install-Module -Name SqlServer -Verbose -Force
    Write-Output "Modulo SqlServer ha sido instalado"
}

# $SQLModule = Get-InstalledModule -Name "PS-Menu"
# if ($SQLModule.Name -eq "PS-Menu") {
#     Write-Output "PS-Menu ya esta instalado"
# }
# else {
#     Write-Output "Instalando Modulo de PS-Menu, no deberia tardar mucho..."
#     Install-Module PS-Menu -Verbose -Force
#     Write-Output "Modulo PS-Menu ha sido instalado"
# }

# Install-Module -Name BurntToast
# Install-Module -Name dbachecks -Verbose -Force

#?===============================================================================
#? Configuración y Secretos de Conexión
#?===============================================================================

$ConfigPath = “./settings.json”

#? Existe una configuración?
if (Test-Path $ConfigPath) {
    #? Como existe, vamos a seleccionarla
    Write-Output "Ya existe un archivo de configuración"
    $SQLBackupConfig = Get-Content $ConfigPath | ConvertFrom-Json
    #? Se selecciono un tipo de encriptación?
    if ([String]::IsNullOrWhiteSpace($SQLBackupConfig.EncryptionType) ) {
        #? Si no se selecciono, vamos a pedir que seleccione
        Write-Warning "Ofrecemos dos tipos de encriptación, AES 256 y Windows Data Protection API. Para seleccionar la encriptación escribe AES o DAPI"
        $EncryptionType = Read-Host -Prompt “Elija el tipo de encriptación (AES, DAPI)”
    }
    else {
        #? Si se selecciono, lo usamos
        Write-Output "Ya existe seleccionaste un tipo de encriptación"
        $EncryptionType = $SQLBackupConfig.EncryptionType
    }
    #? Existen bases de datos a excluir?
    if ([String]::IsNullOrWhiteSpace($SQLBackupConfig.dbToExclude)) {
        #? Si no se excluyeron, vamos a excluirlas
        Write-Warning "Indica las bases de datos que deseas excluir de la copia de seguridad, separadas por comas"
        $dbToExclude = Read-Host -Prompt “¿Cuales son las bases de datos a excluir?”
        $dbToExclude = $dbToExclude.Split(",")
        $dbToExclude += "tempdb"
        $dbToExclude = $dbToExclude
    }
    else {
        #? Si se excluyeron, las seleccionamos
        Write-Output "Ya elegiste las bases de datos a excluir"
        $dbToExclude = $SQLBackupConfig.dbToExclude
        # $dbToExclude = $SQLBackupConfig.dbToExclude | ConvertFrom-Json
    }
    #? ¿Deseamos usar una llave de Encriptación?
    if ([String]::IsNullOrWhiteSpace($SQLBackupConfig.EncryptionKeyBytes) -and $EncryptionType -eq "AES") {
        #? Si no existe llave de encriptación y elegimos AES, vamos a crearla
        $EncryptionKeyBytes = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($EncryptionKeyBytes)        
    }
    elseif ($EncryptionType -eq "DAPI") {
        #? Si elegimos DAPI, no necesitamos una llave de encriptación
        Write-Warning "Ha seleccionado Windows Data Protection API, su llave de encriptación estara ligada a su usuario de Windows."
    }
    else {
        #? Si existe llave de encriptación y elegimos AES, la usamos
        Write-Output "Ya existe llave de encriptación"
        $EncryptionKeyBytes = $SQLBackupConfig.EncryptionKeyBytes
    }
    #? Existen secretos de conexión?
    if ([String]::IsNullOrWhiteSpace($SQLBackupConfig.user) -and [String]::IsNullOrWhiteSpace($SQLBackupConfig.password) -and [String]::IsNullOrWhiteSpace($SQLBackupConfig.hostname)) {
        Write-Warning "Falta una de las credenciales, por favor ingresalas de nuevo"
        if ($EncryptionType -eq "AES") {
            # Clear-Content -Path $SecretPath
            $user = Read-Host "Coloca tu Usuario" -AsSecureString | ConvertFrom-SecureString -Key $EncryptionKeyBytes
            $password = Read-Host "Coloca tu Clave" -AsSecureString | ConvertFrom-SecureString -Key $EncryptionKeyBytes
            $hostname = Read-Host "Coloca la IP de tu servidor (si es local, usa 127.0.0.1)" -AsSecureString | ConvertFrom-SecureString -Key $EncryptionKeyBytes 
        }
        else {
            $user = Read-Host "Coloca tu Usuario" -AsSecureString | ConvertFrom-SecureString
            $password = Read-Host "Coloca tu Clave" -AsSecureString | ConvertFrom-SecureString
            $hostname = Read-Host "Coloca la IP de tu servidor (si es local, usa 127.0.0.1)" -AsSecureString | ConvertFrom-SecureString 
        }
    }
    else {
        Write-Output "Ya existen los secretos de conexión"
        $user = $SQLBackupConfig.user
        $password = $SQLBackupConfig.password
        $hostname = $SQLBackupConfig.hostname
    }
}
else {
    #? No existe una configuración, vamos a crearla
    New-Item -Path $ConfigPath -ItemType File
    Write-Warning "Ofrecemos dos tipos de encriptación, AES 256 y Windows Data Protection API. Para seleccionar la encriptación escribe AES o DAPI"
    $EncryptionType = Read-Host -Prompt “Elija el tipo de encriptación (AES, DAPI)”
    Write-Warning "Indica las bases de datos que deseas excluir de la copia de seguridad, separadas por comas"
    $dbToExclude = Read-Host -Prompt “¿Cuales son las bases de datos a excluir?”
    $dbToExclude = $dbToExclude.Split(",")
    $dbToExclude += "tempdb"
    $dbToExclude = $dbToExclude
    #? ¿Deseamos usar una llave de Encriptación?
    if ($EncryptionType -eq "AES") {
        #? Si no existe llave de encriptación y elegimos AES, vamos a crearla
        $EncryptionKeyBytes = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($EncryptionKeyBytes)
    }
    elseif ($EncryptionType -eq "DAPI") {
        #? Si elegimos DAPI, no necesitamos una llave de encriptación
        Write-Warning "Ha seleccionado Windows Data Protection API, su llave de encriptación estara ligada a su usuario de Windows."
    }
    else {
        Write-Warning "El tipo de encriptación seleccionado no es valido."
    }
    #? Existen secretos de conexión?
    if ($EncryptionType -eq "AES") {
        # Clear-Content -Path $SecretPath
        $user = Read-Host "Coloca tu Usuario" -AsSecureString | ConvertFrom-SecureString -Key $EncryptionKeyBytes
        $password = Read-Host "Coloca tu Clave" -AsSecureString | ConvertFrom-SecureString -Key $EncryptionKeyBytes
        $hostname = Read-Host "Coloca la IP de tu servidor (si es local, usa 127.0.0.1)" -AsSecureString | ConvertFrom-SecureString -Key $EncryptionKeyBytes
    }
    else {
        $user = Read-Host "Coloca tu Usuario" -AsSecureString | ConvertFrom-SecureString
        $password = Read-Host "Coloca tu Clave" -AsSecureString | ConvertFrom-SecureString
        $hostname = Read-Host "Coloca la IP de tu servidor (si es local, usa 127.0.0.1)" -AsSecureString | ConvertFrom-SecureString 
    }
}

Clear-Content -Path $ConfigPath
class Settings {
    [string]$EncryptionType = $EncryptionType
    [string]$user = $user
    [string]$password = $password
    [string]$hostname = $hostname
    $dbToExclude = $dbToExclude
    $EncryptionKeyBytes = $EncryptionKeyBytes
}
$jsonBase = New-Object Settings
ConvertTo-Json -InputObject $jsonBase | Out-File $ConfigPath


#!===============================================================================
#! Configurar Tarea Programada
#!===============================================================================

if (Get-ScheduledTask "SQL Backup" -ErrorAction Ignore) {
    Write-Output "La tarea programada ya existe"
}
else {
    Write-Output "Creando tarea programada"
    $BackupScriptPath = Get-ChildItem -Path "./Backup_Server.ps1" -Recurse | Select-Object -ExpandProperty FullName
    $TaskAction = New-ScheduledTaskAction -Execute 'powershell' -Argument "-ExecutionPolicy Bypass -File $BackupScriptPath"
    $TaskTrigger = New-ScheduledTaskTrigger -Daily -At '06:00'    
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -TaskName "SQL Backup" -Description "Backup de SQL Server"
}

Write-Output "Instalación completada"
