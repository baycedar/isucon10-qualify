#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../

usage() {
  cat 1>&2 << EOS
Usage:
  ${BASH_SOURCE:-${0}} <branch_name>
Description:
  Run the bottleneck analysis of app and DB and push its results to GitHub.
Arguments:
  <branch_name>: A branch name to push analysis results.
EOS
  exit 1
}

if [ ${#} -ne 1 ]; then
  usage
fi

GIT_BRANCH=${1}
if ! git branch --list "${GIT_BRANCH}" | grep "${GIT_BRANCH}" &> /dev/null; then
  echo "There is no branch: ${GIT_BRANCH}" 1>&2
  exit 1
fi

# analyze DBs
export PG_ESTATE_HOST=${PG_ESTATE_HOST:-127.0.0.1}
export PG_CHAIR_HOST=${PG_CHAIR_HOST:-127.0.0.1}
export PGPORT=${PGPORT:-5432}
export PGUSER=${PGUSER:-isucon}
export PGDATABASE=${PGDATABASE:-isuumo}
export PGPASSWORD=${PGPASSWORD:-isucon}
export LANG="C.UTF-8"
psql -h ${PG_ESTATE_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "./conf/analyze_queries.sql" > ./log/estate_db_summary.txt
psql -h ${PG_CHAIR_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "./conf/analyze_queries.sql" > ./log/chair_db_summary.txt

# analyze app
scp 192.168.33.12:/var/log/nginx/access.log ./log/raw/
cat ./log/raw/access.log | kataribe -f ./conf/kataribe.toml > ./log/nginx_summary.txt

# push analysis results
git add ./log/*
git commit -m "add analysis results"
git push origin ${GIT_BRANCH}
