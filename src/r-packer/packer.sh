#!/bin/bash

function usage() {
    echo "Usage: packer.sh env.yaml archivr.tar.gz"
}

ENV_NAME=$1
PACKER_SOURCE=$2
PACKER_TARGET=$3

set -ex

# Install python and R packages
mamba env create \
        --quiet \
        --file ${PACKER_SOURCE}

# Pack all stuff to get rid of conda
exec conda pack \
        --name ${ENV_NAME} \
        --exclude *.js.map \
        --exclude *.pyc \
        --exclude *.a \
        --ignore-missing-files \
        --output ${PACKER_TARGET} \
        --quiet