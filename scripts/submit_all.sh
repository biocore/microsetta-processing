#!/bin/bash

set -e

# https://stackoverflow.com/a/2990533/19741
echoerr() { echo "$@" 1>&2; }

if [[ -z ${TMI_NAME} ]];
then
    echoerr "No name set!"
    exit 1
fi

if [[ -z ${TMI_TITLE} ]];
then
    echoerr "No title set!"
    exit 1
fi

if [[ -z ${TMI_DATATYPE} ]];
then
    echoerr "No data set!"
    exit 1
fi

if [[ -z ${ENV_PACKAGE} ]];
then
    echoerr "No package set!"
    exit 1
fi

if [[ -z ${STUDIES} ]];
then
    echoerr "No studies set!"
    exit 1
fi

cd "$(dirname "$0")"
datetag=$(date +"%Y-%m-%d.%H%M")
logbase=../logs
logdir=${logbase}/${datetag}-${TMI_NAME}
mkdir -p ${logdir}

ENV_PACKAGE=$(echo ${ENV_PACKAGE} | tr " " "|")
qsub_vars="-v ENV_PACKAGE=${ENV_PACKAGE}"
qsub_vars=${qsub_vars},TMI_DATATYPE=${TMI_DATATYPE}
qsub_vars=${qsub_vars},STUDIES=${STUDIES}
qsub_vars=${qsub_vars},TMI_NAME=${TMI_NAME}
qsub_vars=${qsub_vars},TMI_TITLE=$(echo ${TMI_TITLE} | tr " " ".")
qsub_common="-o ${logdir} -e ${logdir} ${qsub_vars}"

if [[ ! -z ${EMAIL} ]];
then
    qsub_common="${qsub_common} -M ${EMAIL} -m ae"
fi

qsub=qsub
if [[ ! $(command -v qsub) ]]; 
then
    qsub=$(pwd)/qsub-capture.sh
fi

cwd=$(pwd)
s01=$(echo "cd ${cwd}; bash 01.redbiom.sh" | ${qsub} -l nodes=1:ppn=1 -l mem=16g -l walltime=8:00:00 ${qsub_common} -N ${TMI_NAME}-01)
s02=$(echo "cd ${cwd}; bash 02.imports.sh" | ${qsub} -W depend=afterok:${s01} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N ${TMI_NAME}-02)
s03=$(echo "cd ${cwd}; bash 03.filtering.sh" | ${qsub} -W depend=afterok:${s02} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N ${TMI_NAME}-03)

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    # taxonomy and phylogeny are "free" from the upstream woltka processing
    # so we do not need wide resources here
    s04a=$(echo "cd ${cwd}; bash 04a.classify.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=1 -l mem=8g -l walltime=1:00:00 ${qsub_common} -N ${TMI_NAME}-04a)
    s04b=$(echo "cd ${cwd}; bash 04b.phylogeny.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=1 -l mem=8g -l walltime=1:00:00 ${qsub_common} -N ${TMI_NAME}-04b)
else
    s04a=$(echo "cd ${cwd}; bash 04a.classify.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=8 -l mem=64g -l walltime=8:00:00 ${qsub_common} -N ${TMI_NAME}-04a)
    s04b=$(echo "cd ${cwd}; bash 04b.phylogeny.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=24 -l mem=128g -l walltime=16:00:00 ${qsub_common} -N ${TMI_NAME}-04b)
fi

s05a=$(echo "cd ${cwd}; bash 05a.rarefy.sh" | ${qsub} -W depend=afterok:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N ${TMI_NAME}-05a)
s05b=$(echo "cd ${cwd}; bash 05b.alpha.sh" | ${qsub} -W depend=afterok:${s05a} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N ${TMI_NAME}-05b)
s05c=$(echo "cd ${cwd}; bash 05c.beta.sh" | ${qsub} -W depend=afterok:${s05a} -l nodes=1:ppn=8 -l mem=24g -l walltime=16:00:00 ${qsub_common} -N ${TMI_NAME}-05c)

if [[ ${ENV_PACKAGE} == *"built|environment"* || ${TMI_NAME} == *"lifestage"* ]];
then
    # as of 3.18.21, q2-taxa collapse was performing a conversion to a dense
    # representation, making a taxa collapse impossible for broad collections
    # with environmental sets of samples
    echoerr "${TMI_NAME}: not performing taxonomy collapse"
    s06_dep=${s05c}
else
    s05d=$(echo "cd ${cwd}; bash 05d.collapse-taxa.sh" | ${qsub} -W depend=afterok:${s04a}:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N ${TMI_NAME}-05d)
    s06_dep="${s05c}:${s05d}"
fi
s06=$(echo "cd ${cwd}; bash 06.subsets-interest.sh" | ${qsub} -W depend=afterok:${s06_dep} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N ${TMI_NAME}-06)
s07a=$(echo "cd ${cwd}; bash 07a.pcoa.sh" | ${qsub} -W depend=afterok:${s06} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N ${TMI_NAME}-07a)

# emit the final job
echo ${s07a}
