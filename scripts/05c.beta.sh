#!/bin/bash

source ./util.sh

mkdir -p ${d}/beta

qiime diversity beta-phylogenetic \
    --i-table ${d}/$(tag_even).biom.qza \
    --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
    --p-n-jobs ${nprocs} \
    --p-metric unweighted_unifrac \
    --p-bypass-tips \
    --o-distance-matrix ${d}/beta/unweighted_unifrac.qza

qiime diversity beta-phylogenetic \
    --i-table ${d}/$(tag_even).biom.qza \
    --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
    --p-n-jobs ${nprocs} \
    --p-metric weighted_normalized_unifrac \
    --p-bypass-tips \
    --o-distance-matrix ${d}/beta/weighted_normalized_unifrac.qza