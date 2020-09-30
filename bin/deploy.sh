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

ssh 192.168.33.11 ~/isuumo/bin/pull_branch.sh "${GIT_BRANCH}"
ssh 192.168.33.12 ~/isuumo/bin/pull_branch.sh "${GIT_BRANCH}"
ssh 192.168.33.13 ~/isuumo/bin/pull_branch.sh "${GIT_BRANCH}"
ssh 192.168.33.11 ~/isuumo/bin/reload/worker_1.sh
ssh 192.168.33.12 ~/isuumo/bin/reload/worker_2.sh
ssh 192.168.33.13 ~/isuumo/bin/reload/worker_3.sh
