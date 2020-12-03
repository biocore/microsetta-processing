#!/bin/bash

source ./util.sh

mkdir -p ${d}/alpha

qiime diversity alpha \
    --i-table ${d}/$(tag_even).biom.qza \
    --p-metric shannon \
    --o-alpha-diversity ${d}/alpha/shannon.qza

qiime diversity alpha-phylogenetic-alt \
    --i-table ${d}/$(tag_even).biom.qza \
    --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
    --p-metric faith_pd \
    --o-alpha-diversity ${d}/alpha/faith_pd.qza
