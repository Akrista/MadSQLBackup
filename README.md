# Backup-SQLServer-Script

Script para realizar backups en SQL. Inicialmente se realizan backups de todas las bases de datos de un servidor SQL Server.

## Usage

Run Install.ps1 script to create the configuration file and install the dependencies necessary to run the script. The installation script also sets a task scheduler task to run the script at a specified time (06:00 Am).

If you want to manually run the script, you can run the script from the command line with the following command:

```powershell
./Backup_Server.ps1
```

## Dependencies

Powershell Module for SQLServer:

```powershell
Install-Module -Name SqlServer
```

## Features List

¿What do we want?

- [ ] SQL Server Backup
  - [x] Local Backup
    - [x] All Instances Backup
  - [ ] Remote Backup
- [ ] MySQL Backup
- [ ] MongoDB Backup
- [ ] App Launcher
  - [x] Backup Configuration
    - [x] Server Credentials
      - [x] Encryption
    - [x] Exclude Databases
  - [ ] Store Backup Configuration
    - [ ] Secure Storage of Configuration Options
  - [ ] Run Backup
  - [x] Setup Task Scheduler on Windows
- [ ] Localization
