#!/bin/bash

set -e

STUDY_TMI=10317
STUDY_META_16S_FECAL=11358.850.2024.11937.11993.10581.10352.10249
STUDY_META_16S_MIXED=2136.10052.10333.11724.11874.1189.1774.550

TYPE_16S=16S
TYPE_WGS=WGS

HUMAN_GUT=human-gut
HUMAN_SKIN=human-skin
HUMAN_ORAL=human-oral
HUMAN_MIXED=human-gut.human-oral.human-skin

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

# Microsetta 16S specific
#TMI_DATATYPE=$TYPE_16S
#ENV_PACKAGE=$HUMAN_GUT
#STUDIES=$STUDY_TMI
#TMI_TITLE="Microsetta 16S fecal samples"
#TMI_NAME=tmi-gut-16S
#sh submit_all.sh
#
#ENV_PACKAGE=$HUMAN_SKIN
#STUDIES=$STUDY_TMI
#TMI_TITLE="Microsetta 16S skin samples"
#TMI_NAME=tmi-skin-16S
#sh submit_all.sh
#
#ENV_PACKAGE=$HUMAN_ORAL
#STUDIES=$STUDY_TMI
#TMI_TITLE="Microsetta 16S oral samples"
#TMI_NAME=tmi-oral-16S
#sh submit_all.sh
#
# Microsetta WGS specific
TMI_DATATYPE=$TYPE_WGS
ENV_PACKAGE=$HUMAN_GUT
STUDIES=$STUDY_TMI
TMI_TITLE="Microsetta WGS fecal samples"
TMI_NAME=tmi-gut-WGS
sh submit_all.sh

# Multipop gut 16S
#TMI_DATATYPE=$TYPE_16S
#ENV_PACKAGE=$HUMAN_GUT
#STUDIES=${STUDY_TMI}.${STUDY_META_16S_FECAL}
#TMI_TITLE="Meta-analysis 16S fecal samples"
#TMI_NAME=meta-gut-16S
#sh submit_all.sh
#
## Multibody site 16S
#TMI_DATATYPE=$TYPE_16S
#ENV_PACKAGE=$HUMAN_MIXED
#STUDIES=${STUDY_TMI}.${STUDY_META_16S_MIXED}
#TMI_TITLE="Meta-analysis 16S multi-bodysite samples"
#TMI_NAME=meta-mixed-16S
#sh submit_all.sh
#
