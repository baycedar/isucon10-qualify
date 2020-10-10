#!/bin/bash
set -uex -o pipefail

WORKSPACE=$(cd $(dirname ${BASH_SOURCE:-${0}})/../; pwd)

GIT_BRANCH=${1}

# prepare source codes
cd ${WORKSPACE}
git fetch origin
git checkout "${GIT_BRANCH}"
git merge --no-progress "origin/${GIT_BRANCH}"
