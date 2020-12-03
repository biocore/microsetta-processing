#!/bin/bash

source ./util.sh

wget \
    -O ${d}/sepp-refs-gg-13-8.qza \
    https://data.qiime2.org/2019.10/common/sepp-refs-gg-13-8.qza

qiime fragment-insertion sepp \
    --i-representative-sequences ${d}/$(tag_mindepth).fna.qza \
    --i-reference-database ${d}/sepp-refs-gg-13-8.qza \
    --o-placements ${d}/$(tag_mindepth).placements.qza \
    --o-tree ${d}/$(tag_mindepth).tree.qza \
    --p-threads ${nprocs}

qiime fragment-insertion filter-features \
    --i-table ${d}/$(tag_mindepth).biom.qza \
    --i-tree ${d}/$(tag_mindepth).tree.qza \
    --o-filtered-table ${d}/$(tag_treeoverlap).biom.qza \
    --o-removed-table ${d}/$(tag_mindepth).nosepp.qza
