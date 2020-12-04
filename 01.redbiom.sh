#!/bin/bash

source ./util.sh

# split studies on ".", and put into an array
# https://stackoverflow.com/a/10586169
IFS='.' read -r -a study_array <<< "${STUDIES}"

study_list=""
for study in "${study_array[@]}"
do
    study_list+=\'
    study_list+=${study}
    study_list+=\',
done

if [ -z "${AG_DEBUG}" ]; then
    redbiom search metadata \
        "where qiita_study_id in (${study_list}) and env_package=='${ENV_PACKAGE}'" > ${d}/$(tag).ids
else
    redbiom search metadata \
        "where qiita_study_id in (${study_list}) and env_package=='${ENV_PACKAGE}'" | head -n 1000 > ${d}/$(tag).ids
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
