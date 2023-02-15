#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCARGO_DIR=${SCRIPT_DIR}/../..

pip3 install -q -U devpi-client devpi-server supervisor
export PATH="$PATH:$HOME/.local/bin"

pushd ${SCARGO_DIR}
mkdir -p temp
pushd temp
# Cleanup of potential previous run
rm -rf gen-config
rm -rf .devpi/
pkill -eF supervisord.pid

# Network config
HOST_IP=localhost
HOST_PORT=4040

# Init devpi
devpi-init --serverdir ./.devpi/server
devpi-gen-config --serverdir ./.devpi/server --port 4040 --host $HOST_IP
supervisord -c gen-config/supervisord.conf

# Wait for server startup
sleep 10

# Login and create pypi index
devpi use http://$HOST_IP:$HOST_PORT
devpi login root --password=""
devpi index -c dev bases=root/pypi

popd # temp

# build and publish on localhost
flit build

export FLIT_INDEX_URL=http://$HOST_IP:$HOST_PORT/root/dev/
export FLIT_USERNAME=root
export FLIT_PASSWORD=""
flit publish

pip config --user set global.index-url http://$HOST_IP:$HOST_PORT/root/dev/
pip config --user set global.trusted-host $HOST_IP

popd # SCARGO_DIR
