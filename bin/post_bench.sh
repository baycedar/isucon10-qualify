#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../; pwd)

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

# check input arguments
if [ ${#} -ne 1 ]; then
  usage
fi
GIT_BRANCH=${1}

# check whether there is a specified branch
cd ${WORKSPACE}
git fetch origin
if ! git branch --list "${GIT_BRANCH}" | grep "${GIT_BRANCH}" &> /dev/null; then
  echo "There is no branch: ${GIT_BRANCH}" 1>&2
  exit 1
fi

# load environment variables
source ${WORKSPACE}/conf/env.sh

# analyze DBs
psql -h ${PG_ESTATE_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "${WORKSPACE}/webapp/psql/udf/udf_analyze_slow_queries.sql"
psql -h ${PG_ESTATE_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "${WORKSPACE}/conf/analyze_queries.sql" > ${WORKSPACE}/log/db_estate_summary.txt

# analyze DBs
psql -h ${PG_CHAIR_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "${WORKSPACE}/webapp/psql/udf/udf_analyze_slow_queries.sql"
psql -h ${PG_CHAIR_HOST} -p ${PGPORT} -U ${PGUSER} -d ${PGDATABASE} \
  -f "${WORKSPACE}/conf/analyze_queries.sql" > ${WORKSPACE}/log/db_chair_summary.txt

# analyze app
ssh ${WEB_HOST} cat /var/log/nginx/access.log | \
  kataribe -f ${WORKSPACE}/conf/kataribe.toml > ${WORKSPACE}/log/nginx_summary.txt

# push analysis results
cd ${WORKSPACE}/log/
git add .
git commit -m "add analysis results"
git push origin ${GIT_BRANCH}
