#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../
NOW=`date +%Y%m%d-%H%M%S`

# reload environment variables
cp -b ./conf/env.sh ~/env.sh

# reload daemon
sudo cp -b ./conf/isuumo.python.service /etc/systemd/system/isuumo.python.service
sudo systemctl daemon-reload

# reload sysctl
sudo cp -b ./conf/sysctl.conf /etc/sysctl.conf
sudo sysctl -p

# reload nginx
sudo cp -b ./conf/nginx.conf /etc/nginx/nginx.conf
sudo cp -b ./conf/nginx_site_isuumo.conf /etc/nginx/sites-available/isuumo.conf
if [ -f /var/log/nginx/access.log ]; then
  sudo mv /var/log/nginx/access.log /var/log/nginx/access_${NOW}.log
fi
sudo touch /var/log/nginx/access.log
sudo chown www-data:adm /var/log/nginx/access.log
sudo systemctl restart nginx.service

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

# reload app
./webapp/python/venv/bin/python -m pip install -r ./webapp/python/requirements.txt
sudo systemctl restart isuumo.python.service
