#!/bin/bash

source ./util.sh

if [[ ${ENV_PACKAGE} == 'human-gut' ]];
then
    qiime feature-table filter-features \
        --i-table ${d}/$(tag).biom.qza \
        --m-metadata-file ${d}/blooms.fna.qza \
        --p-exclude-ids \
        --o-filtered-table ${d}/$(tag_nobloom).biom.qza
else
    cp ${d}/$(tag).biom.qza ${d}/$(tag_nobloom).biom.qza
fi

qiime feature-table filter-features \
    --i-table ${d}/$(tag_nobloom).biom.qza \
    --p-min-frequency ${min_feature_count} \
    --o-filtered-table ${d}/$(tag_minfeat).biom.qza

qiime feature-table filter-samples \
    --i-table ${d}/$(tag_minfeat).biom.qza \
    --p-min-frequency ${min_sample_depth} \
    --o-filtered-table ${d}/$(tag_mindepth).biom.qza

qiime feature-table filter-seqs \
    --i-table ${d}/$(tag_mindepth).biom.qza \
    --i-data ${d}/$(tag).fna.qza \
    --o-filtered-data ${d}/$(tag_mindepth).fna.qza
