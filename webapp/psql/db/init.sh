#!/bin/bash
set -xe
set -o pipefail

CURRENT_DIR=$(cd $(dirname $0);pwd)
export PGHOST=${PGHOST:-127.0.0.1}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-isucon}
export PGDATABASE=${PGDATABASE:-isuumo}
export PGPASSWORD=${PGPASSWORD:-isucon}
export LANG="C.UTF-8"
cd $CURRENT_DIR

cat 0_Schema.sql 1_DummyEstateData.sql 2_DummyChairData.sql 3_CreateIndices.sql | psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE
ssh 192.168.33.12 /home/isucon/isuumo/webapp/redis/init.sh
ssh 192.168.33.13 /home/isucon/isuumo/webapp/redis/init.sh
