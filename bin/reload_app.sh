#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../
NOW=`date +%Y%m%d-%H%M%S`

GIT_BRANCH=$1

# prepare source codes
git fetch origin
git checkout "${GIT_BRANCH}"
git pull origin "${GIT_BRANCH}"

# reload environment variables
cp -b ./conf/env.sh ~/env.sh

# reload daemon
sudo cp -b ./conf/isuumo.python.service /etc/systemd/system/isuumo.python.service
sudo systemctl daemon-reload

# reload sysctl
sudo cp -b ./conf/sysctl.conf /etc/sysctl.conf
sudo sysctl -p

# reload nginx
sudo systemctl stop nginx.service
sudo systemctl disable nginx.service

# stop/disable mysql
sudo systemctl stop mysql.service
sudo systemctl disable mysql.service

# stop/disable postgresql
sudo systemctl stop postgresql.service
sudo systemctl disable postgresql.service

# reload app
sudo systemctl stop isuumo.go.service
sudo systemctl disable isuumo.go.service
./webapp/python/venv/bin/python -m pip install -r ./webapp/python/requirements.txt
sudo systemctl restart isuumo.python.service
sudo systemctl enable isuumo.python.service
