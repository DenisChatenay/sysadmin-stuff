#!/bin/bash
#
####################################################
# Author :  Denis Chatenay                         #
# License : Apache 2.0                             #
# Purpose : Dump and encrypt a MYSQL database      #
# Note :    Works with GPG and BZIP2 libs          #
# Blog :    https://blog.chatenay.me/		   #
####################################################

#######################
#### CONFIGURATION ####
#######################

# MySQL credentials (read-only account - select & lock tables)
MYSQL_HOST="localhost"
MYSQL_DB="my_dbname"
MYSQL_USER="my_dbuser"
MYSQL_PASSWD="my_dbpassword"

# Destination folder where the database will be backed up
DESTINATION_FOLDER="$HOME/backup/databases/"

# Name of the backed up file
BACKUP_FILE=$(date +"%d-%m-%Y")-$MYSQL_DB.sql.bz2

# GPG email used to encrypt
GPG_EMAIL="mygpgemail@example.com"

# Keep backups for 7 days
KEEP_BACKUPS_DAYS=7

##############################
#### ENF OF CONFIGURATION ####
##############################

# Check if the destination folder doesn't exist
if [ ! -d $DESTINATION_FOLDER ];
then
  echo "$0: [$(date)] $DESTINATION_FOLDER does not exist, aborting"
  exit 1
fi

# Check if mysqldump is not installed
if [ ! -x "/usr/bin/mysqldump" ];
then
  echo "$0: [$(date)] /usr/bin/mysqldump is not installed or executable, aborting"
  exit 1
fi

# Check if bzip2 is not installed
if [ ! -x "/bin/bzip2" ];
then
  echo "$0: [$(date)] /bin/bzip2 is not installed or executable, aborting"
  exit 1
fi

# Check if GPG is not installed
if [ ! -x "/usr/bin/gpg" ];
then
  echo "$0: [$(date)] /usr/bin/gpg is not installed or executable, aborting"
  exit 1
fi

# Dump database into a SQL file
DUMP_COMMAND="/usr/bin/mysqldump --extended-insert --host=$MYSQL_HOST --user=$MYSQL_USER --password=$MYSQL_PASSWD $MYSQL_DB"
BZIP_COMMAND="/bin/bzip2 -9"

# Encrypt the database using GPG and the public key of your email address
GPG_COMMAND="/usr/bin/gpg --yes --encrypt --recipient $GPG_EMAIL $DESTINATION_FOLDER$BACKUP_FILE"

# Dump and archive with bzip2
$DUMP_COMMAND | $BZIP_COMMAND > $DESTINATION_FOLDER$BACKUP_FILE

# Check if the archive file has not been created
if [ ! -f $DESTINATION_FOLDER$BACKUP_FILE ];
then
  echo "$0: [$(date)] $DESTINATION_FOLDER$BACKUP_FILE has not been created, aborting"
  exit 1
fi

# Encrypt the archive file with GPG
$GPG_COMMAND

# Check if the final file has not been ciphered
if [ ! -f $DESTINATION_FOLDER$BACKUP_FILE.gpg ];
then
  echo "$0: [$(date)] $DESTINATION_FOLDER$BACKUP_FILE.gpg has not been created, aborting"
  exit 1
fi

# Delete the archive file
rm $DESTINATION_FOLDER$BACKUP_FILE

# The final file has been ciphered
echo "$0: [$(date)] $DESTINATION_FOLDER$BACKUP_FILE.gpg has been ciphered"

# Delete files older than x days
find $DESTINATION_FOLDER/* -mtime +$KEEP_BACKUPS_DAYS -exec rm {} \;

exit 0
