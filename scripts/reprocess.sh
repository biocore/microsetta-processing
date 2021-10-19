#!/bin/bash

set -e
set -u

cd "$(dirname "$0")"

STUDY_TMI=10317
STUDY_HADZA=11358
STUDY_MULTIPOP_16S_FECAL=${STUDY_HADZA}.850.2024.11993.10581.10352.11757.1481.12015.10052.1448.1718.10217.11210.10581
STUDY_LIFESTAGE_16S_FECAL=850.10297.10080.10300.12524.11076.11882.11884.12496.1454.10249.11937.2024.10581
STUDY_BUILTENV=10333.10423
STUDY_VERTEBRATES=11166

TYPE_16S=16S
TYPE_WGS=WGS
SAMPLETYPE_GUT=gut
SAMPLETYPE_ORAL=oral
SAMPLETYPE_SKIN=skin
SAMPLETYPE_ALL=allsamples

DATASET_TMI=tmi
DATASET_HADZA=hadza
DATASET_MULTIPOP=multipop
DATASET_LIFESTAGE=lifestage
DATASET_BUILTENV=builtenv
DATASET_VERTERATES=vertebrates

HUMAN_GUT=human-gut
HUMAN_SKIN=human-skin
HUMAN_ORAL=human-oral
HUMAN_MIXED=${HUMAN_GUT}.${HUMAN_ORAL}.${HUMAN_SKIN}
BUILTENV="built environment"
BUILTENV_HUMAN_MIXED="${HUMAN_MIXED}.${BUILTENV}"
VERTEBRATE=host-associated
HOST_GUT=${HUMAN_GUT}.${VERTEBRATE}

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
mkdir -p ${datetag}/${BUILTENV_HUMAN_MIXED// /_}
mkdir -p ${datetag}/${HOST_GUT}
popd

export QIIME_VERSION=2021.8
SUBMIT_DELAY=10

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
export TMI_NAME=${DATASET_TMI}-${TYPE_WGS}-${SAMPLETYPE_GUT}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_WGS
export ENV_PACKAGE=$HUMAN_SKIN
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta WGS skin samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_WGS}-${SAMPLETYPE_SKIN}
echo $TMI_NAME
#jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_WGS
export ENV_PACKAGE=$HUMAN_ORAL
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta WGS oral samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_WGS}-${SAMPLETYPE_ORAL}
echo $TMI_NAME
#jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_WGS
export ENV_PACKAGE=$HUMAN_MIXED
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta WGS all samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_WGS}-${SAMPLETYPE_ALL}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_WGS
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=$STUDY_HADZA
export TMI_TITLE="Hadza WGS fecal samples"
export TMI_NAME=${DATASET_HADZA}-${TYPE_WGS}-${SAMPLETYPE_GUT}
echo $TMI_NAME
#jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

# Microsetta 16S specific
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_SKIN
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S skin samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_16S}-${SAMPLETYPE_SKIN}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_ORAL
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S oral samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_16S}-${SAMPLETYPE_ORAL}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S fecal samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_16S}-${SAMPLETYPE_GUT}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_MIXED
export STUDIES=$STUDY_TMI
export TMI_TITLE="Microsetta 16S all samples"
export TMI_NAME=${DATASET_TMI}-${TYPE_16S}-${SAMPLETYPE_ALL}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

# Multipop gut 16S
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=${STUDY_TMI}.${STUDY_MULTIPOP_16S_FECAL}
export TMI_TITLE="Meta-analysis 16S fecal samples"
export TMI_NAME=${DATASET_MULTIPOP}-${TYPE_16S}-${SAMPLETYPE_GUT}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=${STUDY_TMI}.${STUDY_LIFESTAGE_16S_FECAL}
export TMI_TITLE="Meta-analysis 16S lifestage fecal samples"
export TMI_NAME=${DATASET_LIFESTAGE}-${TYPE_16S}-${SAMPLETYPE_GUT}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HUMAN_GUT
export STUDIES=$STUDY_HADZA
export TMI_TITLE="Hadza 16S fecal samples"
export TMI_NAME=${DATASET_HADZA}-${TYPE_16S}-${SAMPLETYPE_GUT}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

# non-human comparisons
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$HOST_GUT
export STUDIES=${STUDY_TMI}.${STUDY_VERTEBRATES}
export TMI_TITLE="Meta-analysis 16S vertebrate fecal"
export TMI_NAME=${DATASET_VERTERATES}-${TYPE_16S}-${SAMPLETYPE_GUT}
echo $TMI_NAME
#jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

# Built environment
export TMI_DATATYPE=$TYPE_16S
export ENV_PACKAGE=$BUILTENV_HUMAN_MIXED
export STUDIES=${STUDY_TMI}.${STUDY_BUILTENV}
export TMI_TITLE="Meta-analysis 16S built environment and multi-bodysite samples"
export TMI_NAME=${DATASET_BUILTENV}-${TYPE_16S}-${SAMPLETYPE_ALL}
echo $TMI_NAME
jobs+=($(sh submit_all.sh))
sleep ${SUBMIT_DELAY}

dependency=$(join_by : ${jobs[@]})
cwd=$(pwd)
sbatch_script_common="#!/bin/bash\ncd ${cwd}\n"
echo -e "${sbatch_script_common} bash 08.cleanup.sh" | sbatch --dependency=afterok:${dependency} --export=DATETAG=${datetag} -N 1 -c 1 --mem=1g --time=1:00:00 --job-name TMI-cleanup
