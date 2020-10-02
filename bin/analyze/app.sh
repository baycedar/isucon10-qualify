#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../../

cp /var/log/nginx/access.log ./log/raw/
cat ./log/raw/access.log | kataribe -f ./conf/kataribe.toml > ./log/nginx_summary.txt
