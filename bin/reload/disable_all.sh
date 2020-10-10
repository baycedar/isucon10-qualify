#!/bin/bash
set -uex -o pipefail

CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-${0}}); pwd)

${CUR_DIR}/disable_app.sh
${CUR_DIR}/disable_nginx.sh
${CUR_DIR}/disable_redis.sh
${CUR_DIR}/disable_mysql.sh
${CUR_DIR}/disable_postgresql.sh
