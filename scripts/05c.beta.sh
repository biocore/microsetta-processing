#!/bin/bash

source ./util.sh

mkdir -p ${d}/beta


# storing the bdiv matrices is expensive. these can be cleaned up at the end
# of processing, and greatly reduce the amount of disk space used. however,
# they can be valuable for other uses, so let's establish an easy way to 
# reconstruct them in the future should it be necessary
REBUILD_BETA=${d}/rebuild_beta.sh
echo '#!/bin/bash' > $REBUILD_BETA
echo "source activate qiime2-${QIIME_VERSION}" >> $REBUILD_BETA

# similarly, let's build a file list of things we can safely delete in 
# cleanup
SAFE_TO_DROP=${d}/bdiv_to_drop.droplist

# it is possible to use "fc" to get the last command executed, hwoever it
# seems to hold on to the env variables and doesn't dereference. for the
# need, the variables need to be expanded. so let's just do the ghetto thing
# of creating a copy of the command
bdiv="qiime diversity beta-phylogenetic \
          --i-table ${d}/$(tag_even).biom.qza \
          --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
          --p-threads ${nprocs} \
          --p-metric unweighted_unifrac \
          --p-bypass-tips \
          --o-distance-matrix ${d}/beta/unweighted_unifrac.qza"
echo "${bdiv}" >> $REBUILD_BETA
eval ${bdiv}
echo "${d}/beta/unweighted_unifrac.qza" >> $SAFE_TO_DROP

python k_neighbors.py neighbors \
    --distance-matrix ${d}/beta/unweighted_unifrac.qza \
    --output ${d}/beta/unweighted_unifrac_neighbors.tsv \
    --k 100 \
    --mask-study-id 10317

if [[ ! -z "${TMI_WEIGHTED_UNIFRAC}" ]]; then
    bdiv="qiime diversity beta-phylogenetic \
              --i-table ${d}/$(tag_even).biom.qza \
              --i-phylogeny ${d}/$(tag_mindepth).tree.qza \
              --p-threads ${nprocs} \
              --p-metric weighted_normalized_unifrac \
              --p-bypass-tips \
              --o-distance-matrix ${d}/beta/weighted_normalized_unifrac.qza"
    echo "${bdiv}" >> $REBUILD_BETA
    eval ${bdiv}
    echo "${d}/beta/weighted_normalized_unifrac.qza" >> $SAFE_TO_DROP
        
    python k_neighbors.py neighbors \
        --distance-matrix ${d}/beta/weighted_unifrac.qza \
        --output ${d}/beta/weighted_unifrac_neighbors.tsv \
        --k 100 \
        --mask-study-id 10317
fi
