#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

sudo systemctl stop mysql.service
sudo systemctl disable mysql.service
