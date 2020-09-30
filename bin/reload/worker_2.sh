#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`

./environment.sh
./enable_app.sh
./disable_mysql.sh
./enable_nginx.sh
./disable_postgresql.sh
./disable_redis.sh
