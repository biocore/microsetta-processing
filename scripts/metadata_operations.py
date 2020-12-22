import qiime2
import click
import pandas as pd
import biom
import numpy as np
import os
import json


def _table_and_ids(qza):
    table = qiime2.Artifact.load(qza).view(biom.Table)
    return set(table.ids()), table


def _bloom_counts_and_proportion(original, bloom_free):
    raw_counts = pd.Series(original.sum('sample'), index=original.ids())
    nobloom_counts = pd.Series(np.zeros(len(raw_counts)),
                               index=raw_counts.index)
    nobloom_counts.loc[bloom_free.ids()] = bloom_free.sum('sample')

    # if there are samples in raw counts not in nobloom, set counts to zero
    nobloom_counts.loc[set(raw_counts.index) - set(nobloom_counts.index)] = 0

    return (raw_counts - nobloom_counts,  # number of bloom sequences
            (raw_counts - nobloom_counts) / raw_counts)  # proportion of bloom


def _single_subject(md):
    md = md.copy()
    md['collection_date_only'] = pd.to_datetime(md['collection_date_only'],
                                                errors='coerce')
    md.sort_values('collection_date_only', inplace=True)
    md['single_subject_sample'] = ~md['host_subject_id'].duplicated()
    return md


def _id_overlap(tab, md):
    assert set(tab.ids()).issubset(set(md.index))
    return md.loc[list(tab.ids())]


def _categories_and_types(categories):
    if not categories:
        return [], []

    cats = []
    types = []

    for cat in categories:
        if '::' in cat:
            label, type = cat.split('::', 1)
            assert type in ('categorical', 'numeric')
            cats.append(label)
            types.append(type)
    return cats, types


@click.group()
@click.pass_context
def cli(ctx):
    pass


@cli.command()
@click.option('--metadata', type=click.Path(exists=True), required=True)
@click.option('--output', type=click.Path(exists=False), required=True)
@click.option('--columns', type=click.Path(exists=True), required=True)
def columns_of_interest(metadata, output, columns):
    md = pd.read_csv(metadata, sep='\t', dtype=str).set_index('#SampleID')
    columns = {c.strip() for c in open(columns)}
    md = md[[c for c in md.columns if c in columns]]
    md.to_csv(output, sep='\t', index=True, header=True)


@cli.command()
@click.option('--table', type=click.Path(exists=True), required=True)
@click.option('--metadata', type=click.Path(exists=True), required=True)
@click.option('--output', type=click.Path(exists=False), required=True)
def single_subject(table, metadata, output):
    """Pick a single sample per subject

    The sample picked must exist in the input feature table. And, the sample
    picked is based off the collection date such that the "oldest" sample
    is chosen.
    """
    tab = qiime2.Artifact.load(table).view(biom.Table)
    md = pd.read_csv(metadata, sep='\t', dtype=str).set_index('#SampleID')

    md = _id_overlap(tab, md)
    md = _single_subject(md)

    md.to_csv(output, sep='\t', index=True, header=True)


@cli.command()
@click.option('--table', type=click.Path(exists=True), required=True)
@click.option('--metadata', type=click.Path(exists=True), required=True)
@click.option('--output', type=click.Path(exists=False), required=True)
@click.option('--additional-category', type=str, required=False,
              multiple=True)
def extract_latlong(table, metadata, output, additional_categories):
    """Extract the latitude and longitude variables

    q2-coordinates can operate on these variables but they need to be both
    complete and described as numeric by QIIME2. The metadata from redbiom
    do not satisfy these constraints.

    Metadata are limited to single samples per subject as to not overrepresent
    positions in subsequent graphics.

    Additional category to retain can be specified with
    --additional-category, and can be provided multiple times. The column
    type will be assumed to be categorical unless "::numeric" is used. E.g.,
    "--additional-category age_years::numeric"
    """
    tab = qiime2.Artifact.load(table).view(biom.Table)
    md = pd.read_csv(metadata, sep='\t', dtype=str).set_index('#SampleID')

    md = _id_overlap(tab, md)
    md = _single_subject(md)

    categories, category_types = _categories_and_types(additional_categories)
    categories.extend(['latitude', 'longitude'])
    category_types.extend(['numeric', 'numeric'])

    assert set(categories).issubset(set(md.columns))

    latlong = md[categories]
    for cat, type in zip(categories, category_types):
        if type == 'numeric':
            latlong[cat] = pd.to_numeric(latlong[cat], errors='coerce')
        elif type == 'categorical':
            pass
        else:
            raise ValueError('Unknown type: %s' % type)

    q2md = qiime2.Metadata(latlong)
    q2md.save(output)


@cli.command()
@click.option('--metadata', type=click.Path(exists=True), required=True,
              help="The original redbiom metadata. NOTE: updated inplace")
@click.option('--original-table', type=click.Path(exists=True), required=True,
              help="The original redbiom feature table")
@click.option('--no-bloom-table', type=click.Path(exists=True), required=True,
              help="The table without blooms")
@click.option('--no-singletons-table', type=click.Path(exists=True),
              required=True, help="The table without singletons")
@click.option('--min-count-table', type=click.Path(exists=True), required=True,
              help="The table without low count samples")
@click.option('--only-inserted-table', type=click.Path(exists=True),
              required=True, help="The table with only fragment inserted "
                                  "features")
@click.option('--rarefied-table', type=click.Path(exists=True), required=True,
              help="The rarefied table")
def sample_status(metadata, original_table, no_bloom_table,
                  no_singletons_table, min_count_table, only_inserted_table,
                  rarefied_table):
    md = pd.read_csv(metadata, sep='\t', dtype=str).set_index('#SampleID')
    md_ids = set(md.index)

    original_table_ids, original_table = _table_and_ids(original_table)
    no_bloom_table_ids, no_bloom_table = _table_and_ids(no_bloom_table)
    no_singletons_table, _ = _table_and_ids(no_singletons_table)
    min_count_table, _ = _table_and_ids(min_count_table)
    only_inserted_table, _ = _table_and_ids(only_inserted_table)
    rarefied_table, _ = _table_and_ids(rarefied_table)

    bloom_counts, bloom_proportion = \
        _bloom_counts_and_proportion(original_table, no_bloom_table)

    md['total-reads'] = 0
    total_reads = pd.Series(original_table.sum('sample'),
                            index=original_table.ids())
    md['total-reads'] = total_reads
    md['bloom-counts'] = bloom_counts
    md['bloom-proportion'] = bloom_proportion

    # > 5% bloom and with with more than 1000 sequences / sample raw
    high_bloom = set(bloom_proportion[(bloom_proportion > 0.05) &
                                      (total_reads > 1000)].index)

    category = 'processing-status'
    md[category] = 'All good'

    not_in_redbiom = md_ids - original_table_ids
    entirely_bloom = original_table_ids - no_bloom_table_ids
    lost_from_singletons = no_bloom_table_ids - no_singletons_table
    under_min_count = no_singletons_table - min_count_table
    lost_from_insertions = min_count_table - only_inserted_table
    lost_from_rarefaction = only_inserted_table - rarefied_table

    md.loc[not_in_redbiom, category] = 'Not present in Qiita or missing sequence data'  # noqa
    md.loc[entirely_bloom, category] = 'The sample appears to be entirely bloom'  # noqa
    md.loc[lost_from_singletons, category] = 'Too few sequences before rarefaction'  # noqa
    md.loc[under_min_count & high_bloom, category] = 'High bloom sample'
    md.loc[under_min_count - high_bloom, category] = 'Too few sequences before rarefaction'  # noqa
    md.loc[lost_from_insertions, category] = 'Could not identify placements for associated sequences'  # noqa
    md.loc[lost_from_rarefaction, category] = 'Too few sequences after rarefaction'  # noqa

    md.to_csv(metadata, sep='\t', index=True, header=True)


@cli.command(name='dataset-details')
@click.option('--output', type=click.Path(exists=False),
              help='The path to write the details too')
def dataset_details(output):
    # write out a json object compatible with
    # https://github.com/biocore/microsetta-public-api/blob/e12c8b72b631291b4483a0e27838fe67ecf890af/microsetta_public_api/api/microsetta_public_api.yml#L1464-L1485  # noqa

    studies = os.environ.get('STUDIES')
    env_package = os.environ.get('ENV_PACKAGE')
    title = os.environ.get('TMI_TITLE')
    name = os.environ.get('TMI_NAME')
    datatype = os.environ.get('TMI_DATATYPE')

    if studies is None:
        raise ValueError("No studies provided")
    if env_package is None:
        raise ValueError("No environment provided")
    if title is None:
        raise ValueError("No title provided")
    if name is None:
        raise ValueError("No name provided")
    if datatype is None:
        raise ValueError("No datatype provided")

    obj = {'name': name,
           'title': title.replace('.', ' '),
           'datatype': datatype,
           'environments': env_package.split('.'),
           'qiita-study-ids': studies.split('.')}

    with open(output, 'w') as fp:
        fp.write(json.dumps(obj, indent=2))


if __name__ == '__main__':
    cli()
