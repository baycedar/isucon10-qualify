#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

# install packages
./webapp/python/venv/bin/python -m pip install -r ./webapp/python/requirements.txt

# clear logs
if [ -f ./webapp/python/error.log ]; then
  rm ./webapp/python/error.log
fi
touch ./webapp/python/error.log

# apply new settings
sudo cp -b ./conf/isuumo.python.service /etc/systemd/system/isuumo.python.service
sudo cp -b ./conf/isuumo.python.socket /etc/systemd/system/isuumo.python.socket
sudo systemctl daemon-reload
sudo systemctl start isuumo.python.socket
sudo systemctl enable isuumo.python.socket
sudo systemctl start isuumo.python.service
sudo systemctl enable isuumo.python.service
