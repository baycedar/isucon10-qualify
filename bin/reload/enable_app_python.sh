#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

# install packages
./webapp/python/venv/bin/python -m pip install -r ./webapp/python/requirements.txt

# clear logs
if [ -f ./webapp/go/error.log ]; then
  rm ./webapp/go/error.log
fi
touch ./webapp/go/error.log

# apply new settings
sudo cp -b ./conf/isuumo.go.service /etc/systemd/system/isuumo.go.service
sudo systemctl daemon-reload
sudo systemctl start isuumo.python.socket
sudo systemctl enable isuumo.python.socket
sudo systemctl start isuumo.python.service
sudo systemctl enable isuumo.python.service
