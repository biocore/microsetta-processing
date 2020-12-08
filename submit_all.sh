#!/bin/bash

set -e

if [[ -z ${TMI_DATATYPE} ]];
then
    echo "No data set!"
    exit 1
fi

if [[ -z ${ENV_PACKAGE} ]];
then
    echo "No package set!"
    exit 1
fi

if [[ -z ${STUDIES} ]];
then
    echo "No studies set!"
    exit 1
fi

contact_email=d3mcdonald@eng.ucsd.edu

datetag=$(date +"%Y-%m-%d.%H%M")
logbase=$HOME/ag-4nov2019-redbiom/logs
logdir=${logbase}/${datetag}-${TMI_DATATYPE}
mkdir -p ${logdir}

qsub_common="-v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE},STUDIES=${STUDIES} -o ${logdir} -e ${logdir} -M ${contact_email} -m ae"

cwd=$(pwd)
s01=$(echo "cd ${cwd}; sh 01.redbiom.sh" | qsub -l nodes=1:ppn=1 -l mem=16g -l walltime=8:00:00 ${qsub_common} -N TMI01-${TMI_DATATYPE})
s02=$(echo "cd ${cwd}; sh 02.imports.sh" | qsub -W depend=afterok:${s01} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N TMI02-${TMI_DATATYPE})
s03=$(echo "cd ${cwd}; sh 03.filtering.sh" | qsub -W depend=afterok:${s02} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N TMI03-${TMI_DATATYPE})

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    # taxonomy and phylogeny are "free" from the upstream woltka processing
    # so we do not need wide resources here
    s04a=$(echo "cd ${cwd}; sh 04a.classify.sh" | qsub -W depend=afterok:${s03} -l nodes=1:ppn=1 -l mem=8g -l walltime=1:00:00 ${qsub_common} -N TMI04a-${TMI_DATATYPE})
    s04b=$(echo "cd ${cwd}; sh 04b.phylogeny.sh" | qsub -W depend=afterok:${s03} -l nodes=1:ppn=1 -l mem=8g -l walltime=1:00:00 ${qsub_common} -N TMI04b-${TMI_DATATYPE})
else
    s04a=$(echo "cd ${cwd}; sh 04a.classify.sh" | qsub -W depend=afterok:${s03} -l nodes=1:ppn=8 -l mem=64g -l walltime=8:00:00 ${qsub_common} -N TMI04a-${TMI_DATATYPE})
    s04b=$(echo "cd ${cwd}; sh 04b.phylogeny.sh" | qsub -W depend=afterok:${s03} -l nodes=1:ppn=24 -l mem=128g -l walltime=16:00:00 ${qsub_common} -N TMI04b-${TMI_DATATYPE})
fi

s05a=$(echo "cd ${cwd}; sh 05a.rarefy.sh" | qsub -W depend=afterok:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI05a-${TMI_DATATYPE})
s05b=$(echo "cd ${cwd}; sh 05b.alpha.sh" | qsub -W depend=afterok:${s05a} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI05b-${TMI_DATATYPE})
s05c=$(echo "cd ${cwd}; sh 05c.beta.sh" | qsub -W depend=afterok:${s05a} -l nodes=1:ppn=8 -l mem=16g -l walltime=16:00:00 ${qsub_common} -N TMI05c-${TMI_DATATYPE})
s05d=$(echo "cd ${cwd}; sh 05d.collapse-taxa.sh" | qsub -W depend=afterok:${s04a}:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI05d-${TMI_DATATYPE})
s06=$(echo "cd ${cwd}; sh 06.subsets-interest.sh" | qsub -W depend=afterok:${s05c}:${s05d} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI06-${TMI_DATATYPE})
s07a=$(echo "cd ${cwd}; sh 07a.pcoa.sh" | qsub -W depend=afterok:${s06} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N TMI07a-${TMI_DATATYPE})
