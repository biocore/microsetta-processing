#!/bin/bash

source ./util.sh

if [ -z "${AG_DEBUG}" ]; then
    redbiom search metadata \
        "where qiita_study_id==10317 and env_package=='${ENV_PACKAGE}'" > ${d}/$(tag).ids
else
    redbiom search metadata \
        "where qiita_study_id==10317 and env_package=='${ENV_PACKAGE}'" | head -n 1000 > ${d}/$(tag).ids
fi

redbiom fetch samples \
    --context $redbiom_ctx \
    --output ${d}/$(tag).biom \
    --from ${d}/$(tag).ids \
    --resolve-ambiguities most-reads \
    --md5 true

redbiom fetch sample-metadata \
    --context $redbiom_ctx \
    --output ${d}/$(tag).txt \
    --all-columns \
    --resolve-ambiguities \
    --from ${d}/$(tag).ids

awk '{ print ">" $2 "\n" $1 }' ${d}/$(tag).biom.tsv > ${d}/$(tag).fna
