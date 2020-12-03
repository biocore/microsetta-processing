#!/bin/bash

source ./util.sh

if [[ ${ENV_PACKAGE} == 'human-gut' ]];
then
    qiime feature-table filter-features \
        --i-table ${d}/raw.biom.qza \
        --m-metadata-file ${d}/blooms.fna.qza \
        --p-exclude-ids \
        --o-filtered-table ${d}/raw.biom.nobloom.qza
else
    cp ${d}/raw.biom.qza ${d}/raw.biom.nobloom.qza
fi

qiime feature-table filter-features \
    --i-table ${d}/raw.biom.nobloom.qza \
    --p-min-frequency ${min_feature_count} \
    --o-filtered-table ${d}/raw.biom.nobloom.minfeat.qza

qiime feature-table filter-samples \
    --i-table ${d}/raw.biom.nobloom.minfeat.qza \
    --p-min-frequency ${min_sample_depth} \
    --o-filtered-table ${d}/raw.biom.nobloom.minfeat.mindepth.qza

qiime feature-table filter-seqs \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.qza \
    --i-data ${d}/raw.fna.qza \
    --o-filtered-data ${d}/raw.fna.nobloom.minfeat.mindepth.qza
