#!/bin/bash
set -uex -o pipefail

sudo systemctl stop isuumo.python.service
sudo systemctl disable isuumo.python.service
sudo systemctl stop isuumo.python.socket
sudo systemctl disable isuumo.python.socket
sudo systemctl stop isuumo.go.service
sudo systemctl disable isuumo.go.service
