#!/bin/bash
set -uex -o pipefail

SERVICE_NAME="isuumo.go"
WORKSPACE_DIR=`dirname ${BASH_SOURCE:-${0}}`/../../

# compile app with new sources
cd ${WORKSPACE_DIR}/webapp/go
make

cd ${WORKSPACE_DIR}

# clear logs
if [ -f ./webapp/go/error.log ]; then
  rm ./webapp/go/error.log
fi
touch ./webapp/go/error.log

# apply new settings
sudo cp -b ./conf/${SERVICE_NAME}.service /etc/systemd/system/${SERVICE_NAME}.service
sudo systemctl daemon-reload
sudo systemctl start ${SERVICE_NAME}.service
sudo systemctl enable ${SERVICE_NAME}.service
