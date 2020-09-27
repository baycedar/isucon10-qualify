#!/bin/bash
set -uex -o pipefail

cd `dirname ${BASH_SOURCE:-${0}}`/../
NOW=`date +%Y%m%d-%H%M%S`

GIT_BRANCH=$1

ssh 192.168.33.11 ~/isuumo/bin/reload_db.sh "${GIT_BRANCH}"
ssh 192.168.33.12 ~/isuumo/bin/reload_web_app.sh "${GIT_BRANCH}"
ssh 192.168.33.12 ~/isuumo/bin/reload_app.sh "${GIT_BRANCH}"

