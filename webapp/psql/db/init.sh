#!/bin/bash
set -xe
set -o pipefail

CURRENT_DIR=$(cd $(dirname $0);pwd)
export PG_ESTATE_HOST=${PG_ESTATE_HOST:-127.0.0.1}
export PG_CHAIR_HOST=${PG_CHAIR_HOST:-127.0.0.1}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-isucon}
export PGDATABASE=${PGDATABASE:-isuumo}
export PGPASSWORD=${PGPASSWORD:-isucon}
export LANG="C.UTF-8"
cd $CURRENT_DIR

cat 0_EstateSchema.sql 1_DummyEstateData.sql 2_CreateEstateIndices.sql | \
  psql -h $PG_ESTATE_HOST -p $PGPORT -U $PGUSER -d $PGDATABASE
cat 0_ChairSchema.sql 1_DummyChairData.sql 2_CreateChairIndices.sql | \
  psql -h $PG_CHAIR_HOST -p $PGPORT -U $PGUSER -d $PGDATABASE
