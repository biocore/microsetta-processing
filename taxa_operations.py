import biom
import qiime2
import click
import numpy as np
import pandas as pd

@click.command()
@click.option('--table', type=click.Path(exists=True), required=True)
@click.option('--output', type=click.Path(exists=False), required=True)
@click.option('--top-n', type=int, required=False, default=100)
def top(table, output, top_n):
    table = qiime2.Artifact.load(table).view(biom.Table)

    # remove unnamed things and reads recruiting to human mitochondria
    keep = {i for i in table.ids(axis='observation') if not i.endswith('__')}
    keep -= {"g__human", }
    table.filter(keep, axis='observation', inplace=True)

    # remove taxa not present in at least 10% of samples
    min_ = len(table.ids()) * 0.1

    prevalent = table.filter(lambda v, i, m: (v > 0).sum() > min_,
                             axis='observation', inplace=False)
    prevalent.rankdata(inplace=True)

    # determine the median rank of each taxa
    medians = []
    for v in prevalent.iter_data(axis='observation'):
        medians.append(np.median(v.data))
    medians = pd.Series(medians, index=prevalent.ids(axis='observation'))

    top_n_taxa = medians.sort_values(ascending=False).head(top_n)

    # reduce the original feature table
    rank_top = table.filter(set(top_n_taxa.index), axis='observation',
                            inplace=False)

    # set names to the most specific taxon
    collapse_map = {i: i.rsplit(';')[-1] for i in rank_top.ids(axis='observation')}
    rank_top = rank_top.collapse(lambda i, m: collapse_map[i],
                                 axis='observation', norm=False)
    rank_top.rankdata(inplace=True)

    # store the order in the table
    rank_top_order = medians.sort_values(ascending=False).head(top_n).index
    rank_top_order = {i.rsplit(';')[-1]: idx for idx, i in enumerate(rank_top_order)}
    rank_top.add_metadata({'order': rank_top_order[i] for i in rank_top.ids(axis='observation')},
                          axis='observation')

    ar = qiime2.Artifact.import_data('FeatureTable[Frequency]', rank_top)
    ar.save(output)


if __name__ == '__main__':
    top()
