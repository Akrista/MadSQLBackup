#*===============================================================================
#* Declaración de Variables Principales
#*===============================================================================

$InvocationPath = Split-Path -Parent $($global:MyInvocation.MyCommand.Definition)
#! Archivo de Config
$SQLBackupConfig = $InvocationPath + '\settings.json'
$SQLCredentials = $InvocationPath + '\secret.xml'
$SQLCredentials = Import-CliXml -Path $SQLCredentials

#*===============================================================================
#* Verificar Variables de Entorno
#*===============================================================================

#! Verificamos si existe el archivo de configuración.
if (Test-Path $SQLBackupConfig) {
    Write-Output "Archivo de Configuración Encontrado"
    $SQLBackupConfig = Get-Content $SQLBackupConfig | ConvertFrom-Json
    # Perform Delete file from folder operation
}
else {
    #PowerShell Create directory if not exists
    ./Install.ps1
    $SQLBackupConfig = Get-Content $SQLBackupConfig | ConvertFrom-Json
    Write-Output "Proceso de instalación completado, continua el proceso de respaldo."
}
#! Definimos la carpeta que alojara nuestros Backups
$BackupFolderName = $SQLBackupConfig.backupDirectory
#! Verificamos si existe la ruta que deseamos, en caso contrario, la creamos.
if (Test-Path $BackupFolderName) {
    Write-Output "La carpeta de respaldos ya existe"
    # Perform Delete file from folder operation
}
else {
    #PowerShell Create directory if not exists
    New-Item $BackupFolderName -ItemType Directory
    Write-Output "La carpeta de respaldo ha sido creada de manera exitosa"
}

$ExcludeDatabases = $SQLBackupConfig.dbToExclude

#! Invocamos la consola de comandos de SQL para conectarnos a la base de datos y obtener el nombre de las bases de datos que seran respaldadas
$databases = Invoke-Sqlcmd -ServerInstance '127.0.0.1' -Credential $SQLCredentials -Query "select name from sys.databases"
#! Obtenemos el total de bases de datos que seran respaldadas
$qDb = $databases.Length
#! Posición del progreso
$position = 0

#*===============================================================================
#* Comenzamos a realizar el proceso de respaldo
#*===============================================================================

foreach ($database in ($databases)) {
    $position = ++$position
    $dbName = $database.name
    $pcomplete = [math]::round(($position / $qDb) * 100)
    #! Si la base de datos se llama tempdb, no la respaldamos
    #? Agregaremos una variable que lea una lista de exclusión para bases de datos que no queremos respaldar
    if (($dbName -in $ExcludeDatabases) -or ($dbName -eq "tempdb")) {
        Write-Warning "No se desea guardar la base de datos $dbName"
    }
    else {
        
        #! Respaldamos solamente las bases de datos que se encuentren en el servidor local, en un futuro se puede evaluar si se respalda desde un servidor remoto
        Backup-SqlDatabase -ServerInstance '127.0.0.1' -Database $dbName -Credential $SQLCredentials -BackupFile "$BackupFolderName\$DBName.bak" -Verbose
        tar cvzf "$BackupFolderName\$DBName.tar.gz" "$BackupFolderName\$DBName.bak"
        Write-Output "$dbName respaldada con exito" 
    }
    Write-Progress -Activity "Respaldando Bases de Datos" -Status "$pcomplete% ha sido Completado." -PercentComplete $pcomplete
}
Write-Progress -Activity "Respaldando Bases de Datos" -Status "100% ha sido Completado." -PercentComplete 100
Start-Sleep 1