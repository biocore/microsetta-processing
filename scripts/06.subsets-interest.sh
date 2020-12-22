#!/bin/bash

source ./util.sh

# NOTE: the input (--metadata) is updated inplace
python metadata_operations.py sample-status \
    --metadata ${d}/$(tag).txt \
    --original-table ${d}/$(tag).biom.qza \
    --no-bloom-table ${d}/$(tag_nobloom).biom.qza \
    --no-singletons-table ${d}/$(tag_minfeat).biom.qza \
    --min-count-table ${d}/$(tag_mindepth).biom.qza \
    --only-inserted-table ${d}/$(tag_treeoverlap).biom.qza \
    --rarefied-table ${d}/$(tag_even).biom.qza

python metadata_operations.py single-subject \
    --table ${d}/$(tag_even).biom.qza \
    --metadata ${d}/$(tag).txt \
    --output ${d}/$(tag).denotes-single-subject-sample.txt

python metadata_operations.py columns-of-interest \
    --metadata ${d}/$(tag).txt \
    --columns columns_of_interest.txt \
    --output ${d}/$(tag).columns_of_interest.txt

for ar in ${d}/taxa/*.qza
do
    name=$(basename ${ar} .qza)
    qiime feature-table filter-samples \
        --i-table ${ar} \
        --m-metadata-file ${d}/$(tag).denotes-single-subject-sample.txt \
        --p-where "[single_subject_sample]='True'" \
        --o-filtered-table ${d}/taxa/${name}-single-subject-sample.qza
done
    
for ar in ${d}/beta/*.qza
do
    name=$(basename ${ar} .qza)
    qiime diversity filter-distance-matrix \
        --i-distance-matrix ${ar} \
        --m-metadata-file ${d}/$(tag).denotes-single-subject-sample.txt \
        --p-where "[single_subject_sample]='True'" \
        --o-filtered-distance-matrix ${d}/beta/${name}-single-subject-sample.qza
done