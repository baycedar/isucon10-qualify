#!/bin/bash
set -xe
set -o pipefail

CURRENT_DIR=$(cd $(dirname $0);pwd)
export LANG="C.UTF-8"
cd $CURRENT_DIR

cat estate.txt | redis-cli --pipe
