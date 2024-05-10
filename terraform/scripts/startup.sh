#!/bin/bash

# Install or update needed software
apt-get update
apt-get install -yq git supervisor python3-pip python3-venv jq

# Fetch source code
mkdir /opt/app
git clone https://github.com/GabrielCalazansdm/flask-voting-gcp.git /opt/app

# Python environment setup
python3 -m venv /opt/app/votr/env
source /opt/app/votr/env/bin/activate
pip3 install -r /opt/app/votr/requirements.txt

# Start application
cd /opt/app/
python votr/ca.py
#gunicorn votr.main:app --certfile=server.crt --keyfile=server.key  -b 0.0.0.0:80
gunicorn votr.main:app -b 0.0.0.0:80
