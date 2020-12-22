#!/bin/bash

source ./util.sh

# the unusual syntax is to check for the presence of a substring
# https://stackoverflow.com/a/15394738
if [[ ${ENV_PACKAGE} == *"human-gut"* && ${TMI_DATATYPE} == '16S' ]];
then
    qiime feature-table filter-features \
        --i-table ${d}/$(tag).biom.qza \
        --m-metadata-file ${d}/blooms.fna.qza \
        --p-exclude-ids \
        --o-filtered-table ${d}/$(tag_nobloom).biom.qza
else
    # $(tag) and $(tag_nobloom) are the same filenames if no filtering 
    # is performed, so no need to do anything
    echo "Not filtering blooms"
fi

qiime feature-table filter-features \
    --i-table ${d}/$(tag_nobloom).biom.qza \
    --p-min-frequency ${min_feature_count} \
    --o-filtered-table ${d}/$(tag_minfeat).biom.qza

qiime feature-table filter-samples \
    --i-table ${d}/$(tag_minfeat).biom.qza \
    --p-min-frequency ${min_sample_depth} \
    --o-filtered-table ${d}/$(tag_mindepth).biom.qza

if [[ ${TMI_DATATYPE} == '16S' ]];
then
    # 16S features are sequences, which we reduce here to
    # limit burden on classification and fragment insertion
    qiime feature-table filter-seqs \
        --i-table ${d}/$(tag_mindepth).biom.qza \
        --i-data ${d}/$(tag).fna.qza \
        --o-filtered-data ${d}/$(tag_mindepth).fna.qza
fi
