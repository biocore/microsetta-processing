import click
import qiime2
from skbio import DistanceMatrix
import pandas as pd
import pandas.testing as pdt
import numpy as np
import unittest


class NeighborsTest(unittest.TestCase):
    def test_get_neighbors(self):
        dm = DistanceMatrix(
            [
                [0, 1, 2, 4, 5, 6],
                [1, 0, 3, 4, 5, 6],
                [2, 3, 0, 1, 1, 1],
                [4, 4, 1, 0, 2, 1],
                [5, 5, 1, 2, 0, 3],
                [6, 6, 1, 1, 3, 0],
            ], ids=['s1', 's2', 's3', 's4', 's5', 's6'],
        )
        exp = pd.DataFrame([['s2', 's3'],
                            ['s1', 's3'],
                            ['s4', 's5'],
                            ['s3', 's6'],
                            ['s3', 's4'],
                            ['s3', 's4']],
                           index=['s1', 's2', 's3', 's4', 's5', 's6'],
                           columns=['k0', 'k1'])
        exp.index.name = 'sample_id'
        obs = get_neighbors(dm, 2)
        pdt.assert_frame_equal(obs, exp)

    def test_get_neighbors_mask(self):
        dm = DistanceMatrix(
            [
                [0, 1, 2, 4, 5, 6],
                [1, 0, 3, 4, 5, 6],
                [2, 3, 0, 1, 1, 1],
                [4, 4, 1, 0, 2, 9],
                [5, 5, 1, 2, 0, 3],
                [6, 6, 1, 9, 3, 0],
            ], ids=['A.s1', 'A.s2', 'B.s3', 'B.s4', 'B.s5', 'A.s6'],
        )
        exp = pd.DataFrame([['B.s3', 'B.s4'],
                            ['B.s3', 'B.s4'],
                            ['B.s3', 'B.s5']],
                           index=['A.s1', 'A.s2', 'A.s6'],
                           columns=['k0', 'k1'])
        exp.index.name = 'sample_id'
        obs = get_neighbors(dm, 2, 'A')
        pdt.assert_frame_equal(obs, exp)


def get_neighbors(dm, k, mask_study_id=None):
    """Constructs a dataframe containing only the closest k samples per sample

    Parameters
    ----------
    dm : skbio.DistanceMatrix
        The distance matrix to operate on
    k : int
        The number of samples to retain
    mask_study_id : str, optional
        If specified, only use the mask IDs as sources, and only consider
        neighbors which do not match the mask.

    Returns
    -------
    pd.DataFrame
        Indexed by sample ID, the columns correspond to k0, k1, ... and
        the frame is valued by those similar sample IDs
    """
    ids = dm.ids[:]
    retain = lambda i: True  # noqa

    if mask_study_id is not None:
        ids = [i for i in ids if i.split('.', 1)[0] == mask_study_id]
        retain = lambda i: i.split('.', 1)[0] != mask_study_id  # noqa

    results = []
    for sample_id in ids:
        sample_idx = dm.index(sample_id)
        distances = dm[sample_idx]
        sorted_distances = np.argsort(distances)
        sorted_ids = [dm.ids[i] for i in sorted_distances]

        count = 0
        nearest = []
        for i in sorted_ids[1:]:
            if retain(i):
                nearest.append(i)
                count += 1
            if count >= k:
                break
        results.append([sample_id] + nearest)

    df = pd.DataFrame(results,
                      columns=['sample_id'] + ['k%d' % i for i in range(k)])
    return df.set_index('sample_id')


@click.group()
def cli():
    pass


@cli.command()
@click.option('--distance-matrix', type=click.Path(exists=True), required=True,
              help='The Q2 distance matrix to operate on')
@click.option('--output', type=click.Path(exists=False), required=True,
              help='Where to write the neighbors too')
@click.option('--mask-study-id', type=str, required=False, default=None)
@click.option('--k', type=int, required=True, help='The number of neighbors')
def neighbors(distance_matrix, output, mask_study_id, k):
    dm = qiime2.Artifact.load(distance_matrix).view(DistanceMatrix)

    if mask_study_id is None:
        k = min(len(dm.ids), k + 1) - 1  # account for len(dm) == k
    else:
        non_mask = [i for i in dm.ids if not i.startswith(mask_study_id)]
        k = min(len(non_mask), k + 1) - 1

    kn = get_neighbors(dm, k, mask_study_id)
    kn.to_csv(output, sep='\t', index=True, header=True)


@cli.command()
def test():
    import sys
    unittest.main(argv=sys.argv[:1])


if __name__ == '__main__':
    cli()
