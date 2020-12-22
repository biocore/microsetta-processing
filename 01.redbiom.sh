#!/bin/bash

source ./util.sh

python metadata_operations.py dataset-details --output ${d}/detail.json

study_list=$(create_redbiom_contains ${STUDIES})
env_list=$(create_redbiom_contains ${ENV_PACKAGE})

if [ -z "${AG_DEBUG}" ]; then
    redbiom search metadata \
        "where qiita_study_id in (${study_list}) and env_package in (${env_list})" > ${d}/$(tag).ids
else
    redbiom search metadata \
        "where qiita_study_id in (${study_list}) and env_package in (${env_list})" | head -n 1000 > ${d}/$(tag).ids
fi

redbiom fetch samples \
    --context $redbiom_ctx \
    --output ${d}/$(tag).biom \
    --from ${d}/$(tag).ids \
    --resolve-ambiguities ${ambiguities} \
    --md5 ${hash_features}

redbiom fetch sample-metadata \
    --context $redbiom_ctx \
    --output ${d}/$(tag).txt \
    --all-columns \
    --resolve-ambiguities \
    --from ${d}/$(tag).ids
