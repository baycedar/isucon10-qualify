#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../
NOW=`date +%Y%m%d-%H%M%S`

# reload environment variables
cp -b ./conf/env.sh ~/env.sh

# reload sysctl
sudo cp -b ./conf/sysctl.conf /etc/sysctl.conf
sudo sysctl -p

# reload nginx
sudo systemctl stop nginx.service
sudo systemctl disable nginx.service

# stop/disable mysql
sudo systemctl stop mysql.service
sudo systemctl disable mysql.service

# reload postgresql
sudo cp -b ./conf/postgresql.conf /etc/postgresql/12/main/postgresql.conf
sudo cp -b ./conf/pg_hba.conf /etc/postgresql/12/main/pg_hba.conf
if [ -f /var/log/postgresql/postgresql-12-main.log ]; then
  sudo mv /var/log/postgresql/postgresql-12-main.log /var/log/postgresql/postgresql-12-main_${NOW}.log
fi
sudo touch /var/log/postgresql/postgresql-12-main.log
sudo chown postgres:adm /var/log/postgresql/postgresql-12-main.log
sudo systemctl restart postgresql.service
sudo systemctl enable postgresql.service

# reload redis
sudo systemctl stop redis.service
sudo systemctl disable redis.service

# reload app
sudo systemctl stop isuumo.go.service
sudo systemctl disable isuumo.go.service
sudo systemctl stop isuumo.python.service
sudo systemctl disable isuumo.python.service
