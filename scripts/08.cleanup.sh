#!/bin/bash

source activate qiime2-${QIIME_VERSION}

python cleanup.py create-configuration \
    --base=../results/current \
    --output=../results/current/api-config.json \
    --port 8082 \
    --copy-prefix /projects/tmi-public-results/${DATETAG} \
    --prefix /projects/tmi-public-results/${DATETAG} \
    --actually-copy

python cleanup.py delete-unnecessary-files \
    --base=../results/current 
