#!/bin/bash

set -x
set -e

qiime_version=2020.2
source activate qiime2-${qiime_version}

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    redbiom_ctx=Woltka-wol-072020-Woltka-pergenome-200b91-677a58
    trim_length=None
else
    # NOTE: these need to be consistent!
    redbiom_ctx=Deblur-Illumina-16S-V4-100nt-fbc5b2
    trim_length=100
fi

function base () {
    echo "$(readlink ../current-${ENV_PACKAGE})"
}

if [ ! -d "$(base)" ]; then
    >&2 echo "$(base) does not exist"
    exit 1
fi

d="$(base)/${TMI_DATATYPE}"
mkdir -p ${d}

if [ -z "$PBS_NUM_PPN" ]; then
    nprocs=1
else
    nprocs=$PBS_NUM_PPN
fi
