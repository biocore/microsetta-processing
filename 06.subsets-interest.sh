#!/bin/bash

source ./util.sh

# NOTE: the input (--metadata) is updated inplace
python metadata_operations.py sample-status \
    --metadata ${d}/raw.txt \
    --original-table ${d}/raw.biom.qza \
    --no-bloom-table ${d}/raw.biom.nobloom.qza \
    --no-singletons-table ${d}/raw.biom.nobloom.minfeat.qza \
    --min-count-table ${d}/raw.biom.nobloom.minfeat.mindepth.qza \
    --only-inserted-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.qza \
    --rarefied-table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza

python metadata_operations.py single-subject \
    --table ${d}/raw.biom.nobloom.minfeat.mindepth.sepp.even.qza \
    --metadata ${d}/raw.txt \
    --output ${d}/raw.denotes-single-subject-sample.txt

python metadata_operations.py columns-of-interest \
    --metadata ${d}/raw.txt \
    --columns columns_of_interest.txt \
    --output ${d}/raw.columns_of_interest.txt

for ar in ${d}/taxa/*.qza
do
    name=$(basename ${ar} .qza)
    qiime feature-table filter-samples \
        --i-table ${ar} \
        --m-metadata-file ${d}/raw.denotes-single-subject-sample.txt \
        --p-where "[single_subject_sample]='True'" \
        --o-filtered-table ${d}/taxa/${name}-single-subject-sample.qza
done
    
for ar in ${d}/beta/*.qza
do
    name=$(basename ${ar} .qza)
    qiime diversity filter-distance-matrix \
        --i-distance-matrix ${ar} \
        --m-metadata-file ${d}/raw.denotes-single-subject-sample.txt \
        --p-where "[single_subject_sample]='True'" \
        --o-filtered-distance-matrix ${d}/beta/${name}-single-subject-sample.qza
done
