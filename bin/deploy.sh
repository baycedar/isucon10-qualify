#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../; pwd)

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
git merge --no-progress "origin/${GIT_BRANCH}"

# load environment variables
source ${WORKSPACE}/conf/env.sh

# initialization
for WORKER in ${WORKERS}; do
  # fetch the specified branch on all workers
  ssh ${WORKER} ${WORKSPACE}/bin/reload/branch.sh "${GIT_BRANCH}"
  # stop/disable all functions
  ssh ${WORKER} ${WORKSPACE}/bin/reload/disable_all.sh
  # update server environment
  ssh ${WORKER} ${WORKSPACE}/bin/reload/environment.sh
done

# start/enable service
ssh ${PG_ESTATE_HOST} ${WORKSPACE}/bin/reload/enable_postgresql.sh
ssh ${PG_CHAIR_HOST} ${WORKSPACE}/bin/reload/enable_postgresql.sh
for APP_HOST in ${APP_HOSTS}; do
  ssh ${APP_HOST} ${WORKSPACE}/bin/reload/enable_app.sh
done
ssh ${WEB_HOST} ${WORKSPACE}/bin/reload/enable_nginx.sh
