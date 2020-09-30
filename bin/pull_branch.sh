#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../

GIT_BRANCH=${1}

# prepare source codes
git fetch origin
git checkout "${GIT_BRANCH}"
git pull origin "${GIT_BRANCH}"
