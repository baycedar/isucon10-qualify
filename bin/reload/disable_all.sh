#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`

./disable_app.sh
./disable_nginx.sh
./disable_redis.sh
./disable_mysql.sh
./disable_postgresql.sh
