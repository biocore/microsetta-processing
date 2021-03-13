import click
import qiime2
from skbio import DistanceMatrix
import pandas as pd
import numpy as np
import unittest


class NeighborsTest(unittest.TestCase):
    def test_closest_k_from_distance_matrix(self):
        import pandas.testing as pdt
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


def get_neighbors(dm, k):
    """Constructs a dataframe containing only the closest k samples per sample

    Parameters
    ----------
    dm : skbio.DistanceMatrix
        The distance matrix to operate on
    k : int
        The number of samples to retain

    Returns
    -------
    pd.DataFrame
        Indexed by sample ID, the columns correspond to k0, k1, ... and
        the frame is valued by those similar sample IDs
    """
    results = []
    for sample_id in dm.ids:
        sample_idx = dm.index(sample_id)
        distances = dm[sample_idx]
        # has indices partitioned by distance, around the `kth` entry of the
        # array
        idx = np.argpartition(distances, kth=k)
        # get the k + 1 closest samples (including this sample)
        k_nearest_idx = idx[:k + 1]
        # sort the k closest samples by their distance, so the closest are
        k_distances = distances[k_nearest_idx]
        # remove the sample itself
        sorted_k_indices = np.argsort(k_distances)[1:]
        k_nearest_idx = k_nearest_idx[sorted_k_indices]
        nearest = [sample_id] + [dm.ids[idx]
                                 for idx in k_nearest_idx]
        results.append(nearest)

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
@click.option('--k', type=int, required=True, help='The number of neighbors')
def neighbors(distance_matrix, output, k):
    dm = qiime2.Artifact.load(distance_matrix).view(DistanceMatrix)
    kn = get_neighbors(dm, k)
    kn.to_csv(output, sep='\t', index=True, header=True)


@cli.command()
def test():
    import sys
    unittest.main(argv=sys.argv[:1])


if __name__ == '__main__':
    cli()
