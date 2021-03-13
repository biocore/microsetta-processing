#!/bin/bash

source ./util.sh

python create-configuration.py \
    --base=../results/current \
    --output=../results/current/api-config.json
    
