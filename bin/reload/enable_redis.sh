#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)

# clear logs
if [ -f /var/log/redis/redis-server.log ]; then
  sudo rm /var/log/redis/redis-server.log
fi
sudo touch /var/log/redis/redis-server.log
sudo chown redis:adm /var/log/redis/redis-server.log

# apply new settings
sudo cp -b ${WORKSPACE}/conf/redis.conf /etc/redis/redis.conf
sudo systemctl restart redis-server.service
sudo systemctl enable redis-server.service
