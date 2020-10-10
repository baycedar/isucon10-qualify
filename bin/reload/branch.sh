#!/bin/bash
set -uex -o pipefail

GIT_BRANCH=${1}

# prepare source codes
git fetch origin
git checkout "${GIT_BRANCH}"
git merge "origin/${GIT_BRANCH}"
