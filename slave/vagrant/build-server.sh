#!/bin/bash

if [[ -e /etc/redhat-release ]]; then

# Percona's Yum Repository
yum -d 0 -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm epel-release
# Install Packages
yum -d 0 -y install Percona-Server-server-56 Percona-Server-shared-56 Percona-Server-client-56 Percona-Server-shared-compat percona-toolkit percona-xtrabackup vim-enhanced pigz pwgen

# Setup mysql and disable iptables

/sbin/chkconfig mysql on
/sbin/chkconfig iptables off

/sbin/service iptables stop

# Copy a my.cnf slave to server

rm -f /etc/my.cnf
cp /new_slave_automatic/vagrant/slave.cnf /etc/my.cnf
echo "COPY MY.CNF SUCESS"

# Purge Datadir MySQL

rm -rfv /var/lib/mysql/*

fi
