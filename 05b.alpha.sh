#!/bin/bash

source ./util.sh

mkdir -p ${d}/alpha

qiime diversity alpha \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza \
    --p-metric shannon \
    --o-alpha-diversity ${d}/alpha/shannon.qza

qiime diversity alpha-phylogenetic-alt \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza \
    --i-phylogeny ${d}/raw.nobloom.minfeat.mindepth.sepp.gg138.tree.qza \
    --p-metric faith_pd \
    --o-alpha-diversity ${d}/alpha/faith_pd.qza
