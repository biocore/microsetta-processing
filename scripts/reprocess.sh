#!/bin/bash

set -e

cd "$(dirname "$0")"

STUDY_TMI=10317
STUDY_META_16S_FECAL=11358.850.2024.11937.11993.10581.10352.10249
STUDY_META_16S_MIXED=2136.10052.10333.11724.11874.1189.1774.550

TYPE_16S=16S
TYPE_WGS=WGS

HUMAN_GUT=human-gut
HUMAN_SKIN=human-skin
HUMAN_ORAL=human-oral
HUMAN_MIXED=human-gut.human-oral.human-skin

mkdir -p ../results
pushd ../results
datetag=$(date +"%d%b%Y")

if [[ -d ${datetag} ]];
then
    echo "${datetag} result set already exists!"
    exit 1
fi

mkdir ${datetag}

rm -f current
ln -s ${datetag} current

mkdir -p ${datetag}/${HUMAN_GUT}
mkdir -p ${datetag}/${HUMAN_SKIN}
mkdir -p ${datetag}/${HUMAN_ORAL}
mkdir -p ${datetag}/${HUMAN_MIXED}
popd

# join strings in an array, see 
# https://stackoverflow.com/a/17841619
function join_by { local IFS="$1"; shift; echo "$*"; }

# create an array to house our jobs of interest
declare -a jobs

# Microsetta WGS specific
export TMI_DATATYPE=$TYPE_WGS
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta WGS fecal samples"
export TMI_NAME=tmi-gut-WGS
jobs+=($(sh submit_all.sh))

export TMI_DATATYPE=$TYPE_WGS
export ENV_PACKAGE=$HUMAN_MIXED
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta WGS all samples"
export TMI_NAME=tmi-mixed-WGS
jobs+=($(sh submit_all.sh))

# Microsetta 16S specific
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_SKIN
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S skin samples"
export TMI_NAME=tmi-skin-16S
jobs+=($(sh submit_all.sh))

export ENV_PACKAGE=$HUMAN_ORAL
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S oral samples"
export TMI_NAME=tmi-oral-16S
jobs+=($(sh submit_all.sh))

export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S fecal samples"
export TMI_NAME=tmi-gut-16S
jobs+=($(sh submit_all.sh))

export ENV_PACKAGE=$HUMAN_MIXED
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S all samples"
export TMI_NAME=tmi-all-16S
jobs+=($(sh submit_all.sh))

# Multipop gut 16S
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=${STUDY_TMI}.${STUDY_META_16S_FECAL}
export TMI_TITLE="Meta-analysis 16S fecal samples"
export TMI_NAME=meta-gut-16S
jobs+=($(sh submit_all.sh))

# Multibody site 16S
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_MIXED
export STUDIES=${STUDY_TMI}.${STUDY_META_16S_MIXED}
export TMI_TITLE="Meta-analysis 16S multi-bodysite samples"
export TMI_NAME=meta-mixed-16S
jobs+=($(sh submit_all.sh))

dependency=$(join_by : ${jobs[@]})
qsub -W depend=afterok:${dependency} 08construct-configuration.qsub
echo "cd $(pwd); bash 08.cleanup.sh" | qsub -W depend=afterok:${dependency} -l nodes=1:ppn=1 -l mem=1g -l walltime=1:00:00 -N TMI08-cleanup
