#!/bin/bash

source ./util.sh

qiime feature-table rarefy \
    --i-table ${d}/$(tag_treeoverlap).biom.qza \
    --p-sampling-depth ${min_sample_depth} \
    --o-rarefied-table ${d}/$(tag_even).biom.qza \
    --p-${rarefaction_replacement}-replacement
