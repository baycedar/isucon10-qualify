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

psql -h $PG_ESTATE_HOST -p $PGPORT -U $PGUSER -d $PGDATABASE \
  -f 0_EstateSchema.sql \
  -f 1_DummyEstateData.sql \
  -f 2_CreateEstateIndices.sql \
  -f 3_PostProcessForEstate.sql
psql -h $PG_CHAIR_HOST -p $PGPORT -U $PGUSER -d $PGDATABASE \
  -f 0_ChairSchema.sql \
  -f 1_DummyChairData.sql \
  -f 2_CreateChairIndices.sql \
  -f 3_PostProcessForChair.sql
