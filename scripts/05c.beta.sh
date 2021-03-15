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

python k_neighbors.py neighbors \
    --distance-matrix ${d}/beta/unweighted_unifrac.qza \
    --output ${d}/beta/unweighted_unifrac_neighbors.tsv \
    --k 100

if [[ ! -z "${TMI_WEIGHTED_UNIFRAC}" ]]; then
    qiime diversity beta-phylogenetic \
        --i-table ${d}/$(tag_even).biom.qza \
        --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
        --p-threads ${nprocs} \
        --p-metric weighted_normalized_unifrac \
        --p-bypass-tips \
        --o-distance-matrix ${d}/beta/weighted_normalized_unifrac.qza
    
    python k_neighbors.py neighbors \
        --distance-matrix ${d}/beta/weighted_unifrac.qza \
        --output ${d}/beta/weighted_unifrac_neighbors.tsv \
        --k 100
fi
