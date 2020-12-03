#!/bin/bash

source ./util.sh

wget \
    -O ${d}/sepp-refs-gg-13-8.qza \
    https://data.qiime2.org/2019.10/common/sepp-refs-gg-13-8.qza

qiime fragment-insertion sepp \
    --i-representative-sequences ${d}/raw.fna.nobloom.minfeat.mindepth.qza \
    --i-reference-database ${d}/sepp-refs-gg-13-8.qza \
    --o-placements ${d}/raw.nobloom.minfeat.mindepth.sepp.gg138.placements.qza \
    --o-tree ${d}/raw.nobloom.minfeat.mindepth.sepp.gg138.tree.qza \
    --p-threads ${nprocs}

qiime fragment-insertion filter-features \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.qza \
    --i-tree ${d}/raw.nobloom.minfeat.mindepth.sepp.gg138.tree.qza \
    --o-filtered-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --o-removed-table ${d}/raw.biom.nobloom.mindepth.minfeat.nosepp.qza
