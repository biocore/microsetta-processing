#!/bin/bash

source ./util.sh

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    # for shotgun (woltka) data, we already have taxonomy mappings
    # so let's just obtain them
    wget \
      -O ${d}/$(tag_mindepth).taxonomy.tsv \
      http://ftp.microbio.me/pub/wol2/taxonomy/lineages.txt
    qiime tools import \
        --input-path ${d}/$(tag_mindepth).taxonomy.tsv \
        --output-path ${d}/$(tag_mindepth).taxonomy.qza \
        --type FeatureData[Taxonomy]
else 
    wget \
      -O ${d}/gg-13-8-99-515-806-nb-classifier.qza \
        "https://data.qiime2.org/${QIIME_VERSION}/common/gg-13-8-99-515-806-nb-classifier.qza"

    qiime feature-classifier classify-sklearn \
        --i-classifier ${d}/gg-13-8-99-515-806-nb-classifier.qza \
        --i-reads ${d}/$(tag_mindepth).fna.qza \
        --p-n-jobs ${nprocs} \
        --o-classification ${d}/$(tag_mindepth).taxonomy.qza
fi
