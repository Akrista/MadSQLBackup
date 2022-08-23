sudo apt-get update 
sudo apt-get install gnupg zip
wget https://dev.mysql.com/get/mysql-apt-config_0.8.22-1_all.deb
sudo dpkg -i mysql-apt-config*
rm mysql-apt-config*
sudo apt-get update 
sudo apt install mysql-client

# Backup storage directory 
backupfolder=/var/backups

# MySQL user
user=<user_name>

# MySQL password
password=<password>

# Number of days to store the backup 
keep_day=30 

sqlfile=$backupfolder/all-database-$(date +%d-%m-%Y_%H-%M-%S).sql
zipfile=$backupfolder/all-database-$(date +%d-%m-%Y_%H-%M-%S).zip 
