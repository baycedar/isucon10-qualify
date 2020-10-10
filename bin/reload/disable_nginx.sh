#!/bin/bash
set -uex -o pipefail

sudo systemctl stop nginx.service
sudo systemctl disable nginx.service
