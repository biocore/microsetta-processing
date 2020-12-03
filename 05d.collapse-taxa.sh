#!/bin/bash

source ./util.sh

mkdir -p ${d}/taxa

qiime taxa collapse \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --i-taxonomy ${d}/raw.fna.nobloom.minfeat.mindepth.taxonomy.qza \
    --p-level 6 \
    --o-collapsed-table ${d}/taxa/genus.qza

qiime taxa collapse \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --i-taxonomy ${d}/raw.fna.nobloom.minfeat.mindepth.taxonomy.qza \
    --p-level 5 \
    --o-collapsed-table ${d}/taxa/family.qza

qiime taxa collapse \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --i-taxonomy ${d}/raw.fna.nobloom.minfeat.mindepth.taxonomy.qza \
    --p-level 4 \
    --o-collapsed-table ${d}/taxa/order.qza

qiime taxa collapse \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --i-taxonomy ${d}/raw.fna.nobloom.minfeat.mindepth.taxonomy.qza \
    --p-level 3 \
    --o-collapsed-table ${d}/taxa/class.qza

qiime taxa collapse \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --i-taxonomy ${d}/raw.fna.nobloom.minfeat.mindepth.taxonomy.qza \
    --p-level 2 \
    --o-collapsed-table ${d}/taxa/phylum.qza

python taxa_operations.py \
    --table ${d}/taxa/genus.qza \
    --output ${d}/taxa/top_genera_ranked.qza
