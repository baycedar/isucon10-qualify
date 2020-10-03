#!/bin/bash
set -uex -o pipefail

export PG_ESTATE_HOST=${PG_ESTATE_HOST:-127.0.0.1}
export PG_CHAIR_HOST=${PG_CHAIR_HOST:-127.0.0.1}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-isucon}
export PGDATABASE=${PGDATABASE:-isuumo}
export PGPASSWORD=${PGPASSWORD:-isucon}
export LANG="C.UTF-8"

cd `dirname ${BASH_SOURCE:-${0}}`/../../

psql -h ${PG_ESTATE_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "./conf/analyze_queries.sql" > ./log/estate_db_summary.txt
psql -h ${PG_CHAIR_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "./conf/analyze_queries.sql" > ./log/chair_db_summary.txt
