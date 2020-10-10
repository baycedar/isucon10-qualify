#!/bin/bash
set -uex -o pipefail

sudo systemctl stop redis-server.service
sudo systemctl disable redis-server.service
