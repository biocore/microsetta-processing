#!/bin/bash

set -e


s01=$(echo "cd ${cwd}; bash 01.redbiom.sh" | ${qsub} -l nodes=1:ppn=1 -l mem=16g -l walltime=8:00:00 ${qsub_common} -N TMI01-${TMI_NAME})
s02=$(echo "cd ${cwd}; bash 02.imports.sh" | ${qsub} -W depend=afterok:${s01} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N TMI02-${TMI_NAME})
s03=$(echo "cd ${cwd}; bash 03.filtering.sh" | ${qsub} -W depend=afterok:${s02} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N TMI03-${TMI_NAME})

if [[ ${TMI_DATATYPE} == "WGS" ]];
then
    # taxonomy and phylogeny are "free" from the upstream woltka processing
    # so we do not need wide resources here
    s04a=$(echo "cd ${cwd}; bash 04a.classify.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=1 -l mem=8g -l walltime=1:00:00 ${qsub_common} -N TMI04a-${TMI_NAME})
    s04b=$(echo "cd ${cwd}; bash 04b.phylogeny.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=1 -l mem=8g -l walltime=1:00:00 ${qsub_common} -N TMI04b-${TMI_NAME})
else
    s04a=$(echo "cd ${cwd}; bash 04a.classify.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=8 -l mem=64g -l walltime=8:00:00 ${qsub_common} -N TMI04a-${TMI_NAME})
    s04b=$(echo "cd ${cwd}; bash 04b.phylogeny.sh" | ${qsub} -W depend=afterok:${s03} -l nodes=1:ppn=24 -l mem=128g -l walltime=16:00:00 ${qsub_common} -N TMI04b-${TMI_NAME})
fi

s05a=$(echo "cd ${cwd}; bash 05a.rarefy.sh" | ${qsub} -W depend=afterok:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI05a-${TMI_NAME})
s05b=$(echo "cd ${cwd}; bash 05b.alpha.sh" | ${qsub} -W depend=afterok:${s05a} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI05b-${TMI_NAME})
s05c=$(echo "cd ${cwd}; bash 05c.beta.sh" | ${qsub} -W depend=afterok:${s05a} -l nodes=1:ppn=8 -l mem=24g -l waalltime=16:00:00 ${qsub_common} -N TMI05c-${TMI_NAME})
s05d=$(echo "cd ${cwd}; bash 05d.collapse-taxa.sh" | ${qsub} -W depend=afterok:${s04a}:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI05d-${TMI_NAME})
s06=$(echo "cd ${cwd}; bash 06.subsets-interest.sh" | ${qsub} -W depend=afterok:${s05c}:${s05d} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 ${qsub_common} -N TMI06-${TMI_NAME})
s07a=$(echo "cd ${cwd}; bash 07a.pcoa.sh" | ${qsub} -W depend=afterok:${s06} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 ${qsub_common} -N TMI07a-${TMI_NAME})

# emit the final job
echo ${s07a}
