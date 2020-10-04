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

psql -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE \
  -f ./db/0_EstateSchema.sql \
  -f ./udf/udf_update_estates.sql \
  -f ./udf/trigger_estate_insert.sql \
  -f ./db/1_DummyEstateData.sql \
  -f ./db/2_CreateEstateIndices.sql \
  -f ./db/3_PostProcessForEstate.sql \
  -f ./db/0_ChairSchema.sql \
  -f ./db/1_DummyChairData.sql \
  -f ./db/2_CreateChairIndices.sql \
  -f ./db/3_PostProcessForChair.sql
