#!/bin/bash

source ./util.sh

qiime feature-table rarefy \
    --i-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --p-sampling-depth ${min_sample_depth} \
    --o-rarefied-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza
