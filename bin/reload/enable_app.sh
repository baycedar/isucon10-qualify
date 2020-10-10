#!/bin/bash
set -uex -o pipefail

SERVICE_NAME="isuumo.go"
WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)
GO_DIR="${WORKSPACE}/webapp/go"

# compile app with new sources
cd ${GO_DIR}
make --quiet

# clear logs
if [ -f ${WORKSPACE}/log/app_error.log ]; then
  rm ${WORKSPACE}/log/app_error.log
fi
touch ${WORKSPACE}/log/app_error.log

# apply new settings
sudo cp -b ${WORKSPACE}/conf/${SERVICE_NAME}.service /etc/systemd/system/${SERVICE_NAME}.service
sudo systemctl daemon-reload
sudo systemctl start ${SERVICE_NAME}.service
sudo systemctl enable ${SERVICE_NAME}.service
