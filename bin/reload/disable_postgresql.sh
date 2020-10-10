#!/bin/bash
set -uex -o pipefail

sudo systemctl stop postgresql.service
sudo systemctl disable postgresql.service
