master_server=$1
user_mysql=$2
password_mysql=$3
ip_local=$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
pwd_slave=`pwgen -s 40 1`
lockfile=/tmp/lockfile

if [ ! -e $lockfile ]; then
   trap "rm -f $lockfile; exit" INT TERM EXIT
   touch $lockfile

# CREATE USER OF REPLICATION IN MYSQL MASTER

cat <<-EOF | mysql -h $master_server -u $user_mysql -p$password_mysql
    GRANT REPLICATION SLAVE ON *.* TO 'slave_user'@'$ip_local' IDENTIFIED BY '$pwd_slave';
EOF

if [ $? -eq 0 ]; then

  echo Create user slave with successfully!

else

  echo Failed for create user!
  exit 1
fi

#EXECUTE XTRABACKUP IN MASTER

mkdir /bkp_percona_xtrabackup

ssh root@$1 "innobackupex --user=$user_mysql --password=$password_mysql --stream=tar ./ | pigz | ssh root@$ip_local "cat - > /bkp_percona_xtrabackup/xtrabackup.tar.gz""


if [ $? -eq 0 ]; then

  echo Backup created successfully at Xtrabackup!

else 

  echo Failed to create backup in Xtrabackup!
  exit 1

fi

# PREPARE LOGS

cd /bkp_percona_xtrabackup
tar -zxvf xtrabackup.tar.gz 
sleep 5
innobackupex --apply-log . 

if [ $? -eq 0 ]; then

  echo Prepare Logs Run Successfully!

else

  echo Failed to run Prepare Logs!
  exit 1
fi

#MOVE AND START MYSQL

ls |grep -v xtrabackup |grep -v backup-my.cnf | xargs -I '{}' cp -r '{}' /var/lib/mysql/

chown mysql -R /var/lib/mysql

/etc/init.d/mysql start

if [ $? -eq 0 ]; then

  echo MySQL started successfully!
  
else

  echo Failed to start MySQL!
  exit 1
fi

#PREPARE AND CREATE REPLICATION

LOG_FILE=`cat /bkp_percona_xtrabackup/xtrabackup_binlog_info |awk '{print $1}'`
LOG_POS=`cat /bkp_percona_xtrabackup/xtrabackup_binlog_info |awk '{print $2}'`
echo $LOG_POS

#CHANGE SLAVE TO MASTER

cat <<-EOF | mysql -h $ip_local -u $user_mysql -p$password_mysql
    CHANGE MASTER TO
    MASTER_HOST = '$master_server',
    MASTER_USER = 'slave_user',
    MASTER_PASSWORD = '$pwd_slave',
    MASTER_LOG_FILE = '$LOG_FILE',
    MASTER_LOG_POS  = $LOG_POS ;
EOF

if [ $? -eq 0 ]; then

  echo Replication in MySQL created with success!

else

  echo Failed to create replication in MySQL!
  exit 1
fi


rm $lockfile
   trap - INT TERM EXIT
else
   echo "Critical-section is already running, file /tmp/lockfile exist"
fi
