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
sbatch_vars="--export=ENV_PACKAGE=${ENV_PACKAGE}"
sbatch_vars=${sbatch_vars},TMI_DATATYPE=${TMI_DATATYPE}
sbatch_vars=${sbatch_vars},STUDIES=${STUDIES}
sbatch_vars=${sbatch_vars},TMI_NAME=${TMI_NAME}
sbatch_vars=${sbatch_vars},TMI_TITLE=$(echo ${TMI_TITLE} | tr " " ".")
sbatch_vars=${sbatch_vars},QIIME_VERSION=${QIIME_VERSION}

if [[ -z ${TMPDIR} ]];
then
    sbatch_vars=${sbatch_vars},TMPDIR=${TMPDIR}
fi

if [[ -z ${REDBIOM_HOST} ]];
then
    sbatch_vars=${sbatch_vars},REDBIOM_HOST=${REDBIOM_HOST}
fi

sbatch_common="--kill-on-invalid-dep=yes --parsable --output ${logdir}/%x.%j.out --error ${logdir}/%x.%j.err ${sbatch_vars}"

if [[ -z ${EMAIL} && -f ~/.forward ]];
then
    EMAIL=$(head -n 1 ~/.forward)
fi

if [[ ! -z ${EMAIL} ]];
then
    sbatch_common="${sbatch_common} --mail-user ${EMAIL} --mail-type FAIL,INVALID_DEPEND,TIME_LIMIT_90"
fi

sbatch=sbatch
if [[ ! $(command -v sbatch) ]]; 
then
    sbatch=$(pwd)/sbatch-capture.sh
fi

cwd=$(pwd)
sbatch_script_common="#!/bin/bash\ncd ${cwd}\n"
s01=$(echo -e "${sbatch_script_common} bash 01.redbiom.sh" | ${sbatch} -N 1 -c 1 --mem=16g --time=8:00:00 ${sbatch_common} -J ${TMI_NAME}-01)
s02=$(echo -e "${sbatch_script_common} bash 02.imports.sh" | ${sbatch} --dependency=afterok:${s01} -N 1 -c 1 --mem=16g --time=2:00:00 ${sbatch_common} -J ${TMI_NAME}-02)
s03=$(echo -e "${sbatch_script_common} bash 03.filtering.sh" | ${sbatch} --dependency=afterok:${s02} -N 1 -c 1 --mem=16g --time=2:00:00 ${sbatch_common} -J ${TMI_NAME}-03)

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    # taxonomy and phylogeny are "free" from the upstream woltka processing
    # so we do not need wide resources here
    s04a=$(echo -e "${sbatch_script_common} bash 04a.classify.sh" | ${sbatch} --dependency=afterok:${s03} -N 1 -c 1 --mem=8g --time=1:00:00 ${sbatch_common} -J ${TMI_NAME}-04a)
    s04b=$(echo -e "${sbatch_script_common} bash 04b.phylogeny.sh" | ${sbatch} --dependency=afterok:${s03} -N 1 -c 1 --mem=8g --time=1:00:00 ${sbatch_common} -J ${TMI_NAME}-04b)
else
    s04a=$(echo -e "${sbatch_script_common} bash 04a.classify.sh" | ${sbatch} --dependency=afterok:${s03} -N 1 -c 8 --mem=64g --time=8:00:00 ${sbatch_common} -J ${TMI_NAME}-04a)
    s04b=$(echo -e "${sbatch_script_common} bash 04b.phylogeny.sh" | ${sbatch} --dependency=afterok:${s03} -N 1 -c 24 --mem=128g --time=32:00:00 ${sbatch_common} -J ${TMI_NAME}-04b)
fi

s05a=$(echo -e "${sbatch_script_common} bash 05a.rarefy.sh" | ${sbatch} --dependency=afterok:${s04b} -N 1 -c 1 --mem=16g --time=4:00:00 ${sbatch_common} -J ${TMI_NAME}-05a)
s05b=$(echo -e "${sbatch_script_common} bash 05b.alpha.sh" | ${sbatch} --dependency=afterok:${s05a} -N 1 -c 1 --mem=128g --time=4:00:00 ${sbatch_common} -J ${TMI_NAME}-05b)
s05c=$(echo -e "${sbatch_script_common} bash 05c.beta.sh" | ${sbatch} --dependency=afterok:${s05a} -N 1 -c 8 --mem=64g --time=16:00:00 ${sbatch_common} -J ${TMI_NAME}-05c)

if [[ ${ENV_PACKAGE} == *"built|environment"* || ${TMI_NAME} == *"lifestage"* ]];
then
    # as of 3.18.21, q2-taxa collapse was performing a conversion to a dense
    # representation, making a taxa collapse impossible for broad collections
    # with environmental sets of samples
    echoerr "${TMI_NAME}: not performing taxonomy collapse"
    s06_dep=${s05c}
else
    s05d=$(echo -e "${sbatch_script_common} bash 05d.collapse-taxa.sh" | ${sbatch} --dependency=afterok:${s04a}:${s04b} -N 1 -c 1 --mem=16g --time=4:00:00 ${sbatch_common} -J ${TMI_NAME}-05d)
    s06_dep="${s05c}:${s05d}"
fi
s06=$(echo -e "${sbatch_script_common} bash 06.subsets-interest.sh" | ${sbatch} --dependency=afterok:${s06_dep} -N 1 -c 1 --mem=16g --time=4:00:00 ${sbatch_common} -J ${TMI_NAME}-06)
s07a=$(echo -e "${sbatch_script_common} bash 07a.pcoa.sh" | ${sbatch} --dependency=afterok:${s06} -N 1 -c 1 --mem=256g --time=2:00:00 ${sbatch_common} -J ${TMI_NAME}-07a)

# emit the final job
echo ${s07a}
