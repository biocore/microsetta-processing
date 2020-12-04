#!/bin/bash

set -x
set -e

qiime_version=2020.2
source activate qiime2-${qiime_version}

if [[ -z ${TMI_DATATYPE} ]];
then
    echo "No data set!"
    exit 1
fi

if [[ -z ${STUDIES} ]] ;
then
    echo "No studies specified!"
    exit 1
fi
studies_tag=$(echo ${STUDIES} | tr "." "-")

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    redbiom_ctx=Woltka-wol-072020-Woltka-pergenome-200b91-677a58
    trim_length=None
    min_feature_count=400  # .1% upper bound
    min_sample_depth=400000
    rarefaction_replacement="with"
    ambiguities="merge"
    hash_features="False"
else
    redbiom_ctx=Deblur-Illumina-16S-V4-100nt-fbc5b2
    trim_length=100
    min_feature_count=2
    min_sample_depth=1000
    rarefaction_replacement="no-with"
    ambiguities="most-reads"
    hash_features="True"
fi

function tag_even () {
    echo "$(tag_treeoverlap).even"
}

function tag_treeoverlap () {
    basetag=$(tag_mindepth)
    if [[ ${TMI_DATATYPE} == "16S" ]];
    then
        echo "${basetag}.sepp"
    else
        echo "${basetag}"
    fi
}

function tag_mindepth () {
    echo "$(tag_minfeat).mindepth"
}

function tag_minfeat () {
    echo "$(tag_nobloom).minfeat"
}

function tag_nobloom () {
    basetag=$(tag)
    if [[ ${TMI_DATATYPE} == "WGS" ]];
    then
        echo "${basetag}"
    else
        echo "${basetag}.nobloom"
    fi
}

function tag () {
    echo "raw"
}

function base () {
    if [ -z "${AG_DEBUG}" ]; then
        echo "../$(readlink ../current-${ENV_PACKAGE})"
    else
        mkdir -p ../current-debug
        echo "../current-debug"
    fi
}

if [ ! -d "$(base)" ]; then
    >&2 echo "$(base) does not exist"
    exit 1
fi

d="$(base)/${TMI_DATATYPE}/${studies_tag}"
mkdir -p ${d}

if [ -z "$PBS_NUM_PPN" ]; then
    nprocs=1
else
    nprocs=$PBS_NUM_PPN
fi
