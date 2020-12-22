#!/bin/bash

source ./util.sh

# --metadata
# the original metadata from redbiom
# NOTE: this is updated in place

# --original-table
# the original table is the output from redbiom

# --no-bloom-table
# after the removal of blooms

# --no-singletons-table
# after the removal of singletons

# --min-count-table
# after the removal of samples with fewer than 1000 sequences

# --only-inserted
# after removing features which did not pass fragment insertion

# --rarefied-table
# after rarefaction (as sepp filter may cause a sample to go < 1000 seqs)

python update-sample-summary.py \
    --metadata ${d}/ag.txt \
    --original-table ${d}/ag.biom.qza \
    --no-bloom-table ${d}/ag.biom.nobloom.qza \
    --no-singletons-table ${d}/ag.biom.nobloom.min2.qza \
    --min-count-table ${d}/ag.biom.nobloom.min2.min1k.qza \
    --only-inserted-table ${d}/ag.biom.nobloom.min2.min1k.sepp.qza \
    --rarefied-table ${d}/ag.biom.nobloom.min2.min1k.sepp.even1k.qza
