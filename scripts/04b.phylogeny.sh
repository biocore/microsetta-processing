#!/bin/bash

source ./util.sh

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    # for shotgun (woltka) we already have a phylogeny, so let's just
    # obtain that
    wget \
        -O ${d}/$(tag_mindepth).tree.nwk \
        http://ftp.microbio.me/pub/wol2/phylogeny/tree.nwk
    qiime tools import \
        --input-path ${d}/$(tag_mindepth).tree.nwk \
        --output-path ${d}/$(tag_mindepth).tree.qza \
        --type Phylogeny[Rooted]

    # and the feature space already overlaps with the tree so
    # we get this for free
    # Note that $(tag_mindepth) and $(tag_treeoverlap) are the same filenames 
    # if insertion is not performed
else
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
fi
