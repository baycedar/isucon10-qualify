#!/bin/bash

set -uex -o pipefail

export PG_ESTATE_HOST="192.168.33.11"
export PG_CHAIR_HOST="192.168.33.13"
export PGPORT="5432"
export PGUSER="isucon"
export PGDATABASE="isuumo"
export PGPASSWORD="isucon"
