#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)

# clear logs
if [ -f /var/log/mysql/slow_query.log ]; then
  sudo rm /var/log/mysql/slow_query.log
fi
sudo touch /var/log/mysql/slow_query.log
sudo chown mysql:adm /var/log/mysql/slow_query.log

# apply new settings
sudo cp -b ${WORKSPACE}/conf/mysql.cnf /etc/mysql/mysql.cnf
sudo systemctl restart mysql.service
sudo systemctl enable mysql.service
