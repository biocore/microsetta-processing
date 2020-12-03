#!/bin/bash

source ./util.sh

mkdir -p ${d}/beta

qiime diversity beta-phylogenetic \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza \
    --i-phylogeny ${d}/raw.nobloom.minfeat.mindepth.sepp.gg138.tree.qza \
    --p-n-jobs ${nprocs} \
    --p-metric unweighted_unifrac \
    --p-bypass-tips \
    --o-distance-matrix ${d}/beta/unweighted_unifrac.qza

qiime diversity beta-phylogenetic \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza \
    --i-phylogeny ${d}/raw.nobloom.minfeat.mindepth.sepp.gg138.tree.qza \
    --p-n-jobs ${nprocs} \
    --p-metric weighted_normalized_unifrac \
    --p-bypass-tips \
    --o-distance-matrix ${d}/beta/weighted_normalized_unifrac.qza
