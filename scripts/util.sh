#!/bin/bash

set -x
set -e

source config.bash

# unmunge spaces that are present in some env names
export ENV_PACKAGE=$(echo ${ENV_PACKAGE} | tr "|" " ")

if [[ -z ${QIIME_VERSION} ]]; then
    QIIME_VERSION=2022.2
fi
source activate qiime2-${QIIME_VERSION}

if [[ -z ${PANFS} ]]; then
    export TMPDIR=${PANFS}/tmp
    mkdir -p ${TMPDIR}
fi

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
    if [[ ${ENV_PACKAGE} == "human-skin" ]];
    then
        redbiom_ctx=Woltka-per-genome-WoLr2-67d14f
    else
        redbiom_ctx=Woltka-per-genome-WoLr2-3ab352
    fi
    trim_length=None
    min_relative_abundance=0.0007  # in hadza wgs samples, this gets us close to 16S median observed species
    min_sample_depth=200000
    rarefaction_replacement="with"
    ambiguities="merge"
    hash_features="False"
else
    #redbiom_ctx=Deblur_2021.09-Illumina-16S-V4-90nt-dd6875
    redbiom_ctx=Deblur_2021.09-Illumina-16S-V4-100nt-50b3a2
    trim_length=100
    min_feature_count=2
    min_sample_depth=800
    rarefaction_replacement="no-with"
    ambiguities="merge"
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

if [ -z "$SLURM_CPUS_PER_TASK" ]; then
    nprocs=1
else
    nprocs=$SLURM_CPUS_PER_TASK
fi
