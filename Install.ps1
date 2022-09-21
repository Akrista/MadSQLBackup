#*===============================================================================
#* Instalación de Dependencias
#*===============================================================================

Write-Output "Comenzando proceso de Instalación, por favor espere..."

$SQLModule = Get-InstalledModule -Name "SqlServer"
if ($SQLModule.Name -eq "SqlServer") {
    Write-Output "SqlServer ya esta instalado"
}
else {
    Write-Output "Instalando Modulo de SqlServer, no deberia tardar mucho..."
    Install-Module -Name SqlServer -Verbose -Force
    Write-Output "Modulo SqlServer ha sido instalado"
}

#?===============================================================================
#? Configuración y Secretos de Conexión
#?===============================================================================

$ConfigPath = “./settings.json”
$SecretPath = “./secret.xml"

function dbexclusion {
    Write-Warning "Indica las bases de datos que deseas excluir de la copia de seguridad, separadas por comas"
    $Prompt = Read-Host -Prompt “¿Cuales son las bases de datos a excluir?”
    if ($Prompt -eq "") {
        $result = @()
        $result += "tempdb"
        $result += "current"
        $result += "dbi4"
        $result += "dbi3"
        $result += "dbi2"
        $result += "dbi1"
        $result += "dbi"
        $result += "msdb"
        $result += "model"
        $result += "master"
        $result = $result
    }
    else {
        $result = $Prompt.Split(",")
        $result += "tempdb"
        $result += "current"
        $result += "dbi4"
        $result += "dbi3"
        $result += "dbi2"
        $result += "dbi1"
        $result += "dbi"
        $result += "msdb"
        $result += "model"
        $result += "master"
        $result = $result
    }
    return $result
}

function Find-Folders {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Seleccione un directorio"

    $loop = $true
    while ($loop) {
        if ($browse.ShowDialog() -eq "Ok") {
            $loop = $false
            return $browse.SelectedPath
        }
        else {
            $res = [System.Windows.Forms.MessageBox]::Show("Hiciste clic en cancelar. ¿Deseas volver a seleccionar un directorio o salir?", "Selecciona un directorio", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if ($res -eq "Cancelar") {
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

#? Existe una configuración?
if (Test-Path $ConfigPath) {
    #? Como existe, vamos a seleccionarla
    Write-Output "Ya existe un archivo de configuración"
    $SQLBackupConfig = Get-Content $ConfigPath | ConvertFrom-Json
    #? Existen bases de datos a excluir?
    if ([String]::IsNullOrWhiteSpace($SQLBackupConfig.dbToExclude)) {
        #? Si no se excluyeron, vamos a excluirlas
        $dbToExclude = dbexclusion
        Write-Output "Estas fueron las bases de datos excluidas:" $dbToExclude
    }
    else {
        #? Si se excluyeron, las seleccionamos
        $dbToExclude = $SQLBackupConfig.dbToExclude
        Write-Output "Ya elegiste las bases de datos a excluir:" $dbToExclude
    }
    if ([String]::IsNullOrWhiteSpace($SQLBackupConfig.EncryptionType) ) {
        #? Si no se selecciono, vamos a pedir que seleccione
        Write-Output "Elija la carpeta donde se guardaran los backups"
        $backupDirectory = Find-Folders
    }
    else {
        #? Si se selecciono, lo usamos
        $backupDirectory = $SQLBackupConfig.backupDirectory
        Write-Output "El archivo de configuración ya tiene una ruta para guardar los backups: " $backupDirectory
    }
}
else {
    Write-Output "No existe un archivo de configuración, se creara uno"
    #? No existe una configuración, vamos a crearla
    New-Item -Path $ConfigPath -ItemType File
    $dbToExclude = dbexclusion
    Write-Output "Estas fueron las bases de datos excluidas:" $dbToExclude
    Write-Output "Elija la carpeta donde se guardaran los backups"
    $backupDirectory = Find-Folders
}

if (Test-Path $ConfigPath) {
    Write-Output "Elija la carpeta donde se guardaran los backups"
    Clear-Content -Path $SecretPath
    $credentials = Get-Credential
    $credentials | Export-CliXml -Path $SecretPath
}
else {
    Write-Output "Elija la carpeta donde se guardaran los backups"
    $credentials = Get-Credential
    $credentials | Export-CliXml -Path $SecretPath
}

Clear-Content -Path $ConfigPath
class Settings {
    $backupDirectory = $backupDirectory
    $dbToExclude = $dbToExclude
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
    Write-Output "Indique la hora a la que se hara el backup (formato 24 horas)"
    $backupHour = Read-Host -Prompt “Ejemplo: 06:00”
    $BackupScriptPath = Get-ChildItem -Path "./Backup_Server.ps1" -Recurse | Select-Object -ExpandProperty FullName
    $TaskAction = New-ScheduledTaskAction -Execute 'powershell' -Argument "-ExecutionPolicy Bypass -File $BackupScriptPath"
    $TaskTrigger = New-ScheduledTaskTrigger -Daily -At $backupHour   
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -TaskName "SQL Backup" -Description "Backup de SQL Server"
}

Write-Output "Instalación completada"
