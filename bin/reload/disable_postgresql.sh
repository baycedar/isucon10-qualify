#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

sudo systemctl stop postgresql.service
sudo systemctl disable postgresql.service
