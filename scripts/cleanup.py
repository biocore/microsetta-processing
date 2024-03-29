import glob
import click
import json
import os
from os.path import splitext, join, basename, dirname
import functools
import pathlib
import shutil


@click.group()
def cli():
    pass


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


@cli.command()
@click.option('--base', type=click.Path(exists=True),
              help='The results base directory')
def delete_unnecessary_files(base):
    """Remove files we don't need to have persist"""
    drop_files = glob.glob(join(base, '*/*/*/*.droplist'))
    for fp in drop_files:
        with open(fp) as openfp:
            for f in openfp:
                os.remove(f.strip())


@cli.command()
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
def create_configuration(base, output, port, prefix, copy_prefix,
                         actually_copy):
    detail_files = glob.glob(join(base, '*/*/*/*.json'))
    rewritter = Rewritter()

    datasets = {}
    die = False
    for detail_fp in detail_files:
        detail = json.loads(open(detail_fp).read())
        name = detail.pop('name')

        datatag = name.split('-')[0]
        sampletype = name.split('-')[-1]

        # we'll only keep taxonomy data for TMI subsets
        # as this entity requires a lot of resident memory for the api
        keep_tax = False
        if datatag == 'tmi' and sampletype in ('gut', 'skin', 'oral'):
            keep_tax = True

        results_dir = dirname(detail_fp)
        d = functools.partial(join, results_dir)
        pre = functools.partial(rewritter.replace_prefix, base, prefix)

        # sanity check for completion
        if not os.path.exists(d('beta/pcoa/unweighted_unifrac.qza')):
            click.echo(f"No PCoA: {name}", err=True)
            die = True
            continue

        bloom = ''
        for f in os.listdir(results_dir):
            if 'nobloom' in f:
                bloom = 'nobloom.'
                break

        metadata = pre(d('metadata-by-status/All_good.tsv'))

        for f in glob.glob(d('metadata-by-status/*.tsv')):
            if f.endswith('All_good.tsv'):
                continue

            # copy other status files if they exist
            pre(f)

        alpha = {splitext(basename(f))[0]: pre(f)
                 for f in glob.glob(d('alpha/*.qza'))}

        if keep_tax:
            taxtable = pre(d(f'raw.{bloom}minfeat.mindepth.biom.qza'))
            taxtax = pre(d(f'raw.{bloom}minfeat.mindepth.taxonomy.qza'))
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
            '__alpha__': alpha,
            # '__beta__': beta,
            '__neighbors__': neigh,
            '__pcoa__': {
                'full-dataset': pcoa
                }
            }

        if keep_tax:
            datasets[name]['__taxonomy__'] = {
                'taxonomy': {
                    'table': taxtable,
                    'feature-data-taxonomy': taxtax
                }
            }

    final = {'validate': False,  # disable route checking for pngs
             'resources': {'datasets': datasets},
             'port': str(port)}

    if die:
        import sys
        sys.exit(1)

    with open(output, 'w') as fp:
        fp.write(json.dumps(final, indent=2))

    if actually_copy:
        pathlib.Path(copy_prefix).mkdir(parents=True, exist_ok=True)
        shutil.copy(output, copy_prefix)
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
    cli()
