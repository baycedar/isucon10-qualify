#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`

./environment.sh
./enable_app.sh
./disable_mysql.sh
./disable_nginx.sh
./enable_postgresql.sh
./disable_redis.sh
