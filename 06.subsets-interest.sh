#!/bin/bash

source ./util.sh

# NOTE: the input (--metadata) is updated inplace
python metadata_operations.py sample-status \
    --metadata ${d}/ag.txt \
    --original-table ${d}/ag.biom.qza \
    --no-bloom-table ${d}/ag.biom.nobloom.qza \
    --no-singletons-table ${d}/ag.biom.nobloom.min2.qza \
    --min-count-table ${d}/ag.biom.nobloom.min2.min1k.qza \
    --only-inserted-table ${d}/ag.biom.nobloom.min2.min1k.sepp.qza \
    --rarefied-table ${d}/ag.biom.nobloom.min2.min1k.sepp.even1k.qza

python metadata_operations.py single-subject \
    --table ${d}/ag.biom.nobloom.min2.min1k.sepp.even1k.qza \
    --metadata ${d}/ag.txt \
    --output ${d}/ag.denotes-single-subject-sample.txt

python metadata_operations.py columns-of-interest \
    --metadata ${d}/ag.txt \
    --columns columns_of_interest.txt \
    --output ${d}/ag.columns_of_interest.txt

for ar in ${d}/taxa/*.qza
do
    name=$(basename ${ar} .qza)
    qiime feature-table filter-samples \
        --i-table ${ar} \
        --m-metadata-file ${d}/ag.denotes-single-subject-sample.txt \
        --p-where "[single_subject_sample]='True'" \
        --o-filtered-table ${d}/taxa/${name}-single-subject-sample.qza
done
    
for ar in ${d}/beta/*.qza
do
    name=$(basename ${ar} .qza)
    qiime diversity filter-distance-matrix \
        --i-distance-matrix ${ar} \
        --m-metadata-file ${d}/ag.denotes-single-subject-sample.txt \
        --p-where "[single_subject_sample]='True'" \
        --o-filtered-distance-matrix ${d}/beta/${name}-single-subject-sample.qza
done
