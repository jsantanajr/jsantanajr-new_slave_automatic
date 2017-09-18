#!/bin/bash

if [[ -e /etc/redhat-release ]]; then

# Percona's Yum Repository
yum -d 0 -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
# Install Packages
yum -d 0 -y install Percona-Server-server-56 Percona-Server-shared-56 Percona-Server-client-56 Percona-Server-shared-compat vim-enhanced

# Setup mysql and disable iptables

/sbin/chkconfig mysql on
/sbin/chkconfig iptables off

/sbin/service iptables stop

# ALTER PASSWORD ROOT

echo "root:teste1234" | chpasswd

# Copy a my.cnf slave to server

rm -f /etc/my.cnf
cp /new_slave_automatic/vagrant/master.cnf /etc/my.cnf

/etc/init.d/mysql start

#CHANGE ROOT PASSWORD MYSQL

/usr/bin/mysql -uroot -ss -e " GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' with grant option ; update mysql.user set password = password('root') where user = 'root'; flush privileges; "

fi
