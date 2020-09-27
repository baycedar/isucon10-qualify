#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../
NOW=`date +%Y%m%d-%H%M%S`

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

# reload mysql
sudo cp -b ./conf/mysql.cnf /etc/mysql/mysql.cnf
if [ -f /var/log/mysql/slow_query.log ]; then
  sudo mv /var/log/mysql/slow_query.log /var/log/mysql/slow_query_${NOW}.log
fi
sudo touch /var/log/mysql/slow_query.log
sudo chown mysql:adm /var/log/mysql/slow_query.log
sudo systemctl restart mysql.service

# reload app
./webapp/python/venv/bin/python -m pip install -r ./webapp/python/requirements.txt
sudo systemctl restart isuumo.python.service
