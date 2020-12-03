#!/bin/bash

source ./util.sh

qiime tools import \
    --input-path ${d}/$(tag).biom \
    --output-path ${d}/$(tag).biom.qza \
    --type FeatureTable[Frequency]

if [[ ${TMI_DATATYPE} == "16S" ]];
then
    # obtain blooms for removal from fecal samples
    wget \
        -O ${d}/newbloom.all.fna \
        https://raw.githubusercontent.com/knightlab-analyses/bloom-analyses/master/data/newbloom.all.fna

    # trim the blooms to the length of the 16S reads
    for s in $(grep -v "^>" ${d}/newbloom.all.fna | cut -c 1-${trim_length}); do 
        h=$(echo -n $s | md5sum | awk '{ print $1 }')
        echo -e "${h} ${s}"
    done | sort - | uniq | awk '{ print ">" $1 "\n" $2 }' > ${d}/newbloom.all.${trim_length}nt.fna

    # convert the 16S features into a FASTA file
    awk '{ print ">" $2 "\n" $1 }' ${d}/$(tag).biom.tsv > ${d}/$(tag).fna

    qiime tools import \
        --input-path ${d}/$(tag).fna \
        --output-path ${d}/$(tag).fna.qza \
        --type FeatureData[Sequence]

    qiime tools import \
        --input-path ${d}/newbloom.all.${trim_length}nt.fna \
        --output-path ${d}/blooms.fna.qza \
        --type FeatureData[Sequence]
fi 
