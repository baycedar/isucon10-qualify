#!/bin/bash
set -uex -o pipefail

SERVICE_NAME="isuumo.python"
WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)
PYTHON_DIR="${WORKSPACE}/webapp/python"

# install packages
${PYTHON_DIR}/venv/bin/python -m pip install -r ${PYTHON_DIR}/requirements.txt

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
