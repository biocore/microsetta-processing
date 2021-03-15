import glob
import click
import json
import os
from os.path import splitext, join, basename, dirname
import functools
import pathlib
import shutil


class Rewritter:
    def __init__(self):
        self.srcdst = []

    def replace_prefix(self, old, new, path):
        assert path.startswith(old)
        stripped = path[len(old):]
        if stripped.startswith('/'):
            # os.path.join will not prefix if starting with root
            stripped = stripped[1:]
        replaced = join(new, stripped)
        self.srcdst.append((path, stripped))
        return replaced


@click.command()
@click.option('--base', type=click.Path(exists=True),
              help='The results base directory')
@click.option('--output', type=click.Path(exists=False),
              help='Where to write the configuration too')
@click.option('--port', type=int, default=8082, help='API port')
@click.option('--prefix', type=str, required=True,
              help="Prefix to use on the API server")
@click.option('--copy-prefix', type=str, required=True,
              help="Copy prefix to use when copying files to a dst")
@click.option('--actually-copy', is_flag=True, default=False,
              help="If specified, actually copy the files")
def create_conf(base, output, port, prefix, copy_prefix, actually_copy):
    detail_files = glob.glob(join(base, '*/*/*/*.json'))
    rewritter = Rewritter()

    datasets = {}
    for detail_fp in detail_files:
        detail = json.loads(open(detail_fp).read())
        name = detail.pop('name')

        results_dir = dirname(detail_fp)
        d = functools.partial(join, results_dir)
        pre = functools.partial(rewritter.replace_prefix, base, prefix)

        bloom = ''
        for f in os.listdir(results_dir):
            if 'nobloom' in f:
                bloom = 'nobloom.'
                break

        metadata = pre(d('raw.columns_of_interest.txt'))
        taxtable = pre(d(f'raw.{bloom}minfeat.mindepth.biom.qza'))
        taxtax = pre(d(f'raw.{bloom}minfeat.mindepth.taxonomy.qza'))
        alpha = {splitext(basename(f))[0]: pre(f)
                 for f in glob.glob(d('alpha/*.qza'))}

        # naively limit to unweighted and all samples right now as we're
        # not doing anything with the other data yet
        # beta = {splitext(basename(f))[0]: pre(f)
        #         for f in glob.glob(d('beta/*.qza'))
        #         if f.endswith('unweighted_unifrac.qza')}
        pcoa = {splitext(basename(f))[0]: pre(f)
                for f in glob.glob(d('beta/pcoa/*.qza'))
                if f.endswith('unweighted_unifrac.qza')}

        # unweighted_unifrac_neighbors -> unweighted_unifrac
        neigh = {splitext(basename(f))[0].rsplit('_', 1)[0]: pre(f)
                 for f in glob.glob(d('beta/*.tsv'))
                 if f.endswith('neighbors.tsv')}

        datasets[name] = {
            '__dataset_detail__': detail,
            '__metadata__': metadata,
            '__taxonomy__': {'taxonomy': {
                'table': taxtable,
                'feature-data-taxonomy': taxtax
                }
            },
            '__alpha__': alpha,
            # '__beta__': beta,
            '__neighbors__': neigh,
            '__pcoa__': {
                'full-dataset': pcoa
                }
            }

    final = {'resources': {'datasets': datasets},
             'port': str(port)}

    with open(output, 'w') as fp:
        fp.write(json.dumps(final, indent=2))

    if actually_copy:
        pathlib.Path(copy_prefix).mkdir(parents=True, exist_ok=True)
    else:
        print(f"mkdir -p {copy_prefix}")

    for src, dst in rewritter.srcdst:
        dst = join(copy_prefix, dst)
        dst_dir = dirname(dst)
        if actually_copy:
            print(src, dst)
            pathlib.Path(dst_dir).mkdir(parents=True, exist_ok=True)
            shutil.copy(src, dst)
        else:
            print(f"mkdir -p {dst_dir}")
            print(f"cp {src} {dst}")


if __name__ == '__main__':
    create_conf()
