#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../; pwd)

usage() {
  cat 1>&2 << EOS
Usage:
  ${BASH_SOURCE:-${0}} <branch_name> 2> <error_log>
Description:
  Pull and deploy source codes to workers.
Arguments:
  <branch_name>: A branch name to deploy source codes.
  <error_log>: A log file to forward stderr messages.
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

# sync local sources with remote ones
git checkout "${GIT_BRANCH}"
git merge --quiet "origin/${GIT_BRANCH}"

# load environment variables
echo "load environment variables..."
source ${WORKSPACE}/conf/env.sh

# initialization
echo "initialize workers [${WORKERS}]..."
for WORKER in ${WORKERS}; do
  echo "${WORKER}:"
  echo "  fetch remote sources..."
  ssh ${WORKER} ${WORKSPACE}/bin/reload/branch.sh "${GIT_BRANCH}"
  echo "  disable all services..."
  ssh ${WORKER} ${WORKSPACE}/bin/reload/disable_all.sh
  echo "  update server environment..."
  ssh ${WORKER} ${WORKSPACE}/bin/reload/environment.sh
  echo "${WORKER} done."
done

# start/enable service
echo "start a database server on ${PG_ESTATE_HOST}"
ssh ${PG_ESTATE_HOST} ${WORKSPACE}/bin/reload/enable_postgresql.sh
echo "start a database server on ${PG_CHAIR_HOST}"
ssh ${PG_CHAIR_HOST} ${WORKSPACE}/bin/reload/enable_postgresql.sh
for APP_HOST in ${APP_HOSTS}; do
  echo "start an app-server on ${APP_HOST}"
  ssh ${APP_HOST} ${WORKSPACE}/bin/reload/enable_app.sh
done
echo "start a web-server on ${WEB_HOST}"
ssh ${WEB_HOST} ${WORKSPACE}/bin/reload/enable_nginx.sh
