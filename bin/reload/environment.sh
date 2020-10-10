#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../../; pwd)

# reload environment variables
cp -b ${WORKSPACE}/conf/env.sh ${HOME}/env.sh
cp -b ${WORKSPACE}/conf/pgpass ${HOME}/.pgpass
chmod 600 ~/.pgpass

# reload sysctl
sudo cp -b ${WORKSPACE}/conf/sysctl.conf /etc/sysctl.conf
sudo sysctl -p --quiet
