#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../

usage() {
  cat 1>&2 << EOS
Usage:
  ${BASH_SOURCE:-${0}} <branch_name>
Description:
  Pull and deploy source codes to workers.
Arguments:
  <branch_name>: A branch name to deploy source codes.
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

WORKERS=("192.168.33.11" "192.168.33.12" "192.168.33.13")

# initialization
for WORKER in ${WORKERS}; do
  # fetch the specified branch on all workers
  ssh ${WORKER} ~/isuumo/bin/reload/branch.sh "${GIT_BRANCH}"
  # stop/disable all functions
  ssh ${WORKER} ~/isuumo/bin/reload/disable_all.sh
  # update server environment
  ssh ${WORKER} ~/isuumo/bin/reload/environment.sh
done

# load environment variables
source ~/env.sh

# start/enable service
ssh ${PG_ESTATE_HOST} ~/isuumo/bin/reload/enable_postgresql.sh
ssh ${PG_CHAIR_HOST} ~/isuumo/bin/reload/enable_postgresql.sh
APP_HOST_LIST=(${APP_HOSTS})
for APP_HOST in ${APP_HOST_LIST}; do
  ssh ${APP_HOST} ~/isuumo/bin/reload/enable_app.sh
done
ssh ${WEB_HOST} ~/isuumo/bin/reload/enable_nginx.sh
