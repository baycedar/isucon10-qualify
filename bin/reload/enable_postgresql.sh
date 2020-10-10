#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)

# clear logs
if [ -f /var/log/postgresql/postgresql-12-main.log ]; then
  sudo rm /var/log/postgresql/postgresql-12-main.log
fi
sudo touch /var/log/postgresql/postgresql-12-main.log
sudo chown postgres:adm /var/log/postgresql/postgresql-12-main.log

# apply new settings
sudo cp -b ${WORKSPACE}/conf/postgresql.conf /etc/postgresql/12/main/postgresql.conf
sudo cp -b ${WORKSPACE}/conf/pg_hba.conf /etc/postgresql/12/main/pg_hba.conf
sudo systemctl restart postgresql.service
sudo systemctl enable postgresql.service
