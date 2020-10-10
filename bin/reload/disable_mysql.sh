#!/bin/bash
set -uex -o pipefail

sudo systemctl stop mysql.service
sudo systemctl disable mysql.service
