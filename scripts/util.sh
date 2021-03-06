#!/bin/bash

set -x
set -e

# unmunge spaces that are present in some env names
export ENV_PACKAGE=$(echo ${ENV_PACKAGE} | tr "|" " ")

if [[ -z ${QIIME_VERSION} ]]; then
    QIIME_VERSION=2020.11
fi
source activate qiime2-${QIIME_VERSION}

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

function create_redbiom_contains () {
    # convert "foo.bar" -> "'foo','bar'"

    # split studies on ".", and put into an array
    # https://stackoverflow.com/a/10586169
    IFS='.' read -r -a arr <<< "${1}"

    rblist=""
    for elm in "${arr[@]}"
    do
        rblist+=\'
        rblist+=${elm}
        rblist+=\',
    done
    echo $rblist
}

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
        # if wgs, we do not filter for bloom
        echo "${basetag}"
    else
        if [[ ${ENV_PACKAGE} == *"human-gut"* ]];
        then
            # if not wgs, and using human gut samples, we filter for bloom
            echo "${basetag}.nobloom"
        else
            echo "${basetag}"
        fi
    fi
}

function tag () {
    echo "raw"
}

function base () {
    if [ -z "${AG_DEBUG}" ]; then
        normalized=${ENV_PACKAGE// /_}
        echo "../results/current/${normalized}"
    else
        mkdir -p ../current-debug
        echo "../current-debug"
    fi
}

if [ ! -d "$(base)" ]; then
    >&2 echo "$(base) does not exist"
    exit 1
fi

d="$(base)/${TMI_DATATYPE}/${STUDIES}"
mkdir -p ${d}

if [ -z "$PBS_NUM_PPN" ]; then
    nprocs=1
else
    nprocs=$PBS_NUM_PPN
fi
