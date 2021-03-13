#!/bin/bash

source ./util.sh

mkdir -p ${d}/beta

qiime diversity beta-phylogenetic \
    --i-table ${d}/$(tag_even).biom.qza \
    --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
    --p-threads ${nprocs} \
    --p-metric unweighted_unifrac \
    --p-bypass-tips \
    --o-distance-matrix ${d}/beta/unweighted_unifrac.qza

qiime diversity beta-phylogenetic \
    --i-table ${d}/$(tag_even).biom.qza \
    --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
    --p-threads ${nprocs} \
    --p-metric weighted_normalized_unifrac \
    --p-bypass-tips \
    --o-distance-matrix ${d}/beta/weighted_normalized_unifrac.qza

python k_neighbors.py \
    --distance-matrix ${d}/beta/unweighted_unifrac.qza \
    --output ${d}/beta/unweighted_unifrac_neighbors.qza \
    --k 100

python k_neighbors.py \
    --distance-matrix ${d}/beta/weighted_unifrac.qza \
    --output ${d}/beta/weighted_unifrac_neighbors.qza \
    --k 100
