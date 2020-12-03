#!/bin/bash

source ./util.sh

wget \
      -O ${d}/gg-13-8-99-515-806-nb-classifier.qza \
        "https://data.qiime2.org/${qiime_version}/common/gg-13-8-99-515-806-nb-classifier.qza"

qiime feature-classifier classify-sklearn \
    --i-classifier ${d}/gg-13-8-99-515-806-nb-classifier.qza \
    --i-reads ${d}/$(tag_mindepth).fna.qza \
    --p-n-jobs ${nprocs} \
    --o-classification ${d}/$(tag_mindepth).taxonomy.qza
