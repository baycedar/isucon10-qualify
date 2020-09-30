#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

sudo systemctl stop nginx.service
sudo systemctl disable nginx.service
