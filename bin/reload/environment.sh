#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

# reload environment variables
cp -b ./conf/env.sh ~/env.sh
cp -b ./conf/pgpass ~/.pgpass
chmod 600 ~/.pgpass

# reload sysctl
sudo cp -b ./conf/sysctl.conf /etc/sysctl.conf
sudo sysctl -p
