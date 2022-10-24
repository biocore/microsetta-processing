import click
import qiime2, biom
import numpy as np
import numpy.testing as npt


def filter(tab, min_rel_abund):
    counts = {s: v for s, v in zip(tab.ids(), tab.sum('sample'))}

    def transform_f(v, i, m):
        normed = v / v.sum()
        v[normed < min_rel_abund] = 0
        return v

    return tab.transform(transform_f, axis='sample',
                         inplace=False).remove_empty()


def test_filter():
    tab = biom.Table(np.array([[0, 1, 2],
                               [2, 3, 1],
                               [1, 0, 2]]),
                     ['a', 'b', 'c'],
                     ['x', 'y', 'z'])
    obs = filter(tab, 0.4)
    exp = biom.Table(np.array([[0, 0, 2], [2, 3, 0], [0, 0, 2]]),
                     ['a', 'b', 'c'],
                     ['x', 'y', 'z'])
    npt.assert_almost_equal(obs.matrix_data.toarray(),
                            exp.matrix_data.toarray())
test_filter()


@click.command()
@click.option('--table', type=click.Path(exists=True), required=True)
@click.option('--output', type=click.Path(exists=False), required=True)
@click.option('--min-rel-abund', type=float, required=True)
def filter(table, output, min_rel_abund):
    tab = qiime2.Artifact.load(table).view(biom.Table)
    tab = filter(tab, min_rel_abund)
    tab_ar = qiime2.Artifact.import_data('FeatureTable[Frequency]', tab)
    tab_ar.save(output)


if __name__ == '__main__':
    filter()
