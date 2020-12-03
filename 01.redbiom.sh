#!/bin/bash

source ./util.sh

if [ -z "${AG_DEBUG}" ]; then
    redbiom search metadata \
        "where qiita_study_id==10317 and env_package=='${ENV_PACKAGE}'" > ${d}/raw.ids
else
    redbiom search metadata \
        "where qiita_study_id==10317 and env_package=='${ENV_PACKAGE}'" | head -n 100 > ${d}/raw.ids
fi

redbiom fetch samples \
    --context $redbiom_ctx \
    --output ${d}/raw.biom \
    --from ${d}/raw.ids \
    --resolve-ambiguities most-reads \
    --md5 true

redbiom fetch sample-metadata \
    --context $redbiom_ctx \
    --output ${d}/raw.txt \
    --all-columns \
    --resolve-ambiguities \
    --from ${d}/raw.ids

awk '{ print ">" $2 "\n" $1 }' ${d}/raw.biom.tsv > ${d}/raw.fna
