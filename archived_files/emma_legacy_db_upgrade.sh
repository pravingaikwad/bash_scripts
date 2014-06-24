#!/bin/sh


# Flag to interrupt script execution on error
set -e


# DATABASE VARIABLES
mysql_h=''
mysql_u=''
mysql_p=''
mysql_d=''


# DATABASE COMMANDS
mysql_cmd="mysql -h $mysql_h -u$mysql_u -p$mysql_p"
mysqldump_cmd="mysqldump -h$mysql_h -u$mysql_u -p$mysql_p"

# variables
today=$(date +%Y%m%d)
client_version=1245
upgrade_version=1312
base_dir='/home/pg/pre_upgrade_schema_check'
compressed_file_db_backup='/home/pg/client_db_backups/20130714_esph--skip-triggers.sql.gz'
file_db_backup='/home/pg/client_db_backups/20130714_esph--skip-triggers.sql'
upgrade_script_dir=$base_dir/Updates
log=$base_dir/"log_"$mysql_d"_"$today
flag_db_restore=1
flag_db_upgrade=1

echo "$(date) Script to upgrade database called..." >> $log

# initialise mysql variables
echo -e "Enter the mysql hostname and press [ENTER]:"
read mysql_h
# if variable is empty set the default value
if [ -z "$mysql_h" ]; then
  mysql_h='localhost'
fi


echo -e "Enter the mysql username and press [ENTER]:"
read mysql_u
# if variable is empty set the default value
if [ -z "$mysql_u" ]; then
  mysql_u='test_user'
fi

read -s -p "Enter the password for username - $mysqlu and press [ENTER]:" mysql_p
# if variable is empty set the default value
if [ -z "$mysql_p" ]; then
  mysql_p='test_password'
fi

echo -e "Enter the mysql database name and press [ENTER]:"
read mysql_d
# if variable is empty set the default value
if [ -z "$mysql_d" ]; then
  mysql_d='test_password'
fi


echo $(date)' - if [ $flag_db_restore -eq 1 ]; then' >> $log

# if [ $flag_db_restore -eq 1 ]; then
if [ $flag_db_restore -eq 1 ]; then

echo "$(date) - uncompress the database backup file..." >> $log

# check if the db backup compressed file exists 
  if [ -f $compressed_file_db_backup ]; then
    gunzip $compressed_file_db_backup >> $log 2>&1
  fi

echo "$(date) - database backup file uncompressed..." >> $log

# check if the db backup file exists
  if [ -f $file_db_backup ]; then

    echo "$(date) - drop and recreate database..." >> $log

    # drop and recreate database
    $mysql_cmd <<EOFMYSQL
      DROP DATABASE IF EXISTS $mysql_d;
      CREATE DATABASE IF NOT EXISTS $mysql_d;
EOFMYSQL

    echo "$(date) - database dropped and recreated..." >> $log

    echo "$(date) - restore database backup file..." >> $log

    $mysql_cmd $mysql_d < $file_db_backup >> $log 2>&1

    echo "$(date) - database backup file restored..." >> $log

  fi

echo "$(date) - compress the database backup file..." >> $log

# check if the db backup compressed file exists 
  if [ -f $file_db_backup ]; then
    gzip $file_db_backup >> $log 2>&1
  fi

echo "$(date) - database backup file compressed..." >> $log

# if [ $flag_db_restore -eq 1 ]; then
fi


echo $(date)' - if [ $flag_db_upgrade -eq 1 ]; then' >> $log

# if [ $flag_db_upgrade -eq 1 ]; then
if [ $flag_db_upgrade -eq 1 ]; then

  # SETUP BASE_SCHEMA TO PROPOSED VERSION
  echo "$(date) cd $upgrade_script_dir ">> $log 2>&1
  cd $upgrade_script_dir >> $log 2>&1


  filedir=$(ls)
  for d in $filedir
  do
	  if [ $d -gt $client_version ]; then
		  #statements
	      if [ -d $d ];
	      then
		      # echo $d $upgrade_version >> $log 2>&1
		      cd $d >> $log 2>&1
		      files=$(ls)
		      for f in $files
		      do
			      echo "$(date) - executing $d/$f ..." >> $log 2>&1
			      $mysql_cmd $mysql_d < $f >> $log 2>&1
			      echo "$(date) - $d/$f complete" >> $log 2>&1
		      done
		      cd .. >> $log 2>&1
		      if [ $d -gt $upgrade_version ];
			      then
				      echo "$(date) exit called - $version $upgrade_version" >> $log 2>&1
				      # UPDATE VERSION TABLE
				      $mysql_cmd <<EOFMYSQL
				      UPDATE $mysql_d.version SET current_version = $d;
EOFMYSQL
		      # $mysqldump_cmd -R --no-data $mysql_d > $base_dir/$mysql_d"_no_data.sql"
				      exit
		      fi
	  else
		  echo "2nd exit called - $version $upgrade_version" >> $log 2>&1
		  exit
	  fi
      else
	  echo "$d $client_version $upgrade_version" >> $log 2>&1 
	  fi
  done

# if [ $flag_db_upgrade -eq 1 ]; then
fi