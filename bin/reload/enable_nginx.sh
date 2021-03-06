#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)

# clear logs
if [ -f /var/log/nginx/access.log ]; then
  sudo rm /var/log/nginx/access.log
fi
sudo touch /var/log/nginx/access.log
sudo chown www-data:adm /var/log/nginx/access.log

# apply new settings
sudo cp -b ${WORKSPACE}/conf/nginx.conf /etc/nginx/nginx.conf
sudo cp -b ${WORKSPACE}/conf/nginx_site_isuumo.conf /etc/nginx/sites-available/isuumo.conf
sudo systemctl restart nginx.service
sudo systemctl enable nginx.service
