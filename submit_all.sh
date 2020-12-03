#!/bin/bash

cwd=$(pwd)
s01=$(echo "cd ${cwd}; sh 01.redbiom.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -l nodes=1:ppn=1 -l mem=16g -l walltime=8:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI01-${TMI_DATATYPE})
s02=$(echo "cd ${cwd}; sh 02.imports.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s01} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI02-${TMI_DATATYPE})
s03=$(echo "cd ${cwd}; sh 03.filtering.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s02} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI03-${TMI_DATATYPE})
s04a=$(echo "cd ${cwd}; sh 04a.classify.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s03} -l nodes=1:ppn=8 -l mem=64g -l walltime=8:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI04a-${TMI_DATATYPE})
s04b=$(echo "cd ${cwd}; sh 04b.phylogeny.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s03} -l nodes=1:ppn=24 -l mem=128g -l walltime=16:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI04b-${TMI_DATATYPE})
s05a=$(echo "cd ${cwd}; sh 05a.rarefy.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI05a-${TMI_DATATYPE})
s05b=$(echo "cd ${cwd}; sh 05b.alpha.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s05a} -l nodes=1:ppn=1 -l mem=16g -l walltime=4:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI05b-${TMI_DATATYPE})
s05c=$(echo "cd ${cwd}; sh 05c.beta.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s05a} -l nodes=1:ppn=8 -l mem=16g -l walltime=16:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI05c-${TMI_DATATYPE})
s05d=$(echo "cd ${cwd}; sh 05d.collapse-taxa.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s04a}:${s04b} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI05d-${TMI_DATATYPE})
s06=$(echo "cd ${cwd}; sh 06.subsets-interest.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s05c}:${s05d} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI06-${TMI_DATATYPE})
s07a=$(echo "cd ${cwd}; sh 07a.pcoa.sh" | qsub -v ENV_PACKAGE=${ENV_PACKAGE},TMI_DATATYPE=${TMI_DATATYPE} -W depend=afterok:${s06} -l nodes=1:ppn=1 -l mem=16g -l walltime=2:00:00 -M d3mcdonald@eng.ucsd.edu -m abe -N TMI07a-${TMI_DATATYPE})
