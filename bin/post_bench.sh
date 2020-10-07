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

# load environment variables
source /home/isucon/env.sh

# analyze DBs
psql -h ${PG_ESTATE_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "./conf/analyze_queries.sql" > ./log/db_estate_summary.txt

# analyze DBs
psql -h ${PG_CHAIR_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "./conf/analyze_queries.sql" > ./log/db_chair_summary.txt

# analyze app
ssh ${WEB_HOST} cat /var/log/nginx/access.log | \
  kataribe -f ./conf/kataribe.toml > ./log/nginx_summary.txt

# push analysis results
git add ./log/*
git commit -m "add analysis results"
git push origin ${GIT_BRANCH}
