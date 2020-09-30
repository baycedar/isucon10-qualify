#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

sudo systemctl stop redis-server.service
sudo systemctl disable redis-server.service
