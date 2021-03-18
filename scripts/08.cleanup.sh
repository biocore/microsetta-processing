#!/bin/bash

python create-configuration.py \
    --base=../results/current \
    --output=../results/current/api-config.json \
    --port 8082 \
    --copy-prefix /projects/tmi-public-results/current \
    --prefix /tmi-public-results 
