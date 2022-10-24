import qiime2
import click
import pandas as pd
import biom
import numpy as np
import os
import json
import pathlib
from random import choice
import string


def _anonymized_id(existing):
    label = ''.join([choice(string.ascii_letters) for i in range(8)])
    while label in existing:
        label = ''.join([choice(string.ascii_letters) for i in range(8)])
    return label


def _anonymize_sample_and_study(random_studies, study_grp, df):
    # generate a unique random study ID
    study = _anonymized_id(random_studies)
    random_studies.add(study)

    # generate N random sample IDs
    random_samples = set()
    for i in range(len(study_grp)):
        sample = _anonymized_id(random_samples)
        random_samples.add(sample)
    assert len(random_samples) == len(study_grp)

    # create the sample IDs with the study ID
    samples = [f'{study}.{i}' for i in random_samples]
    mapping = {u: v for u, v in zip(study_grp['#SampleID'], samples)}

    # update the metadata
    df.loc[study_grp.index, '#SampleID'] = samples

    # we _do not_ update qiita_study_id as it is used later on. instead,
    # we will drop that field entirely
    return mapping


def _anonymize_fuzz_bmi(study_grp, df):
    n_samples = len(study_grp)
    cols = ['host_body_mass_index', 'bmi']

    for c in cols:
        if c not in study_grp.columns:
            continue

        vals = pd.to_numeric(study_grp[c], errors='coerce')

        if (vals.isnull().sum() / n_samples) > 0.95:
            # this really doesn't look numeric...
            continue

        nonnull = n_samples - vals.isnull().sum()
        fuzz = np.random.uniform(0.5, 1.5, nonnull)
        vals[~vals.isnull()] += fuzz

        df.loc[vals[~vals.isnull()].index, c] = vals


def _anonymize_fuzz_age(study_grp, df):
    n_samples = len(study_grp)

    cols = ['age_years', 'week', 'host_age', 'day_of_life', 'age',
            'consent_age']
    for c in cols:
        if c not in study_grp.columns:
            continue

        vals = pd.to_numeric(study_grp[c], errors='coerce')
        if (vals.isnull().sum() / n_samples) > 0.95:
            # this really doesn't look numeric...
            continue

        nonnull = n_samples - vals.isnull().sum()
        fuzz = np.random.uniform(0.5, 1.5, nonnull)
        vals[~vals.isnull()] += fuzz

        df.loc[vals[~vals.isnull()].index, c] = vals


def _anonymize_fuzz_remove(study_grp, df):
    cols = ['country', 'geo_loc_name', 'latitude', 'longitude', 'title',
            'qiita_study_id']

    for c in cols:
        if c not in study_grp.columns:
            continue

        df.loc[study_grp.index, c] = 'Removed'


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
@click.option('--input-output', type=click.Path(exists=True), required=True)
def anonymize_fields(input_output):
    md = pd.read_csv(input_output, sep='\t', dtype=str)

    random_studies = set()
    for study, study_grp in md.groupby('qiita_study_id'):
        if study == '10317':
            continue
        _anonymize_fuzz_age(study_grp, md)
        _anonymize_fuzz_bmi(study_grp, md)
        _anonymize_fuzz_remove(study_grp, md)

    md.to_csv(input_output, sep='\t', index=False, header=True)


@cli.command()
@click.option('--input-output-md', type=click.Path(exists=True), required=True)
@click.option('--input-output-tab', type=click.Path(exists=True), required=True)
def anonymize_sample_ids(input_output_md, input_output_tab):
    md = pd.read_csv(input_output_md, sep='\t', dtype=str)
    tab = biom.load_table(input_output_tab)

    mapping = dict()
    random_studies = set()
    for study, study_grp in md.groupby('qiita_study_id'):
        if study == '10317':
            continue

        mapping.update(_anonymize_sample_and_study(random_studies, study_grp,
                                                   md))

    tab.update_ids(mapping, inplace=True, strict=False)
    with biom.util.biom_open(input_output_tab, 'w') as fp:
        tab.to_hdf5(fp, 'asd')

    md.to_csv(input_output_md, sep='\t', index=False, header=True)


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

    path = os.path.dirname(metadata)
    pathlib.Path(f"{path}/metadata-by-status").mkdir(parents=True,
                                                     exist_ok=True)
    for name, grp in md.groupby('processing-status'):
        if len(grp) > 0:
            name = name.replace(' ', '_')
            grp.to_csv(f"{path}/metadata-by-status/{name}.tsv", sep='\t',
                       index=True, header=True)


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


def _remap_if_needed(df, remap, default):
    new_values = [None] * len(df)
    values = []
    for grp in remap:
        for col, mapping in grp.items():
            print(col)
            print(df[col].value_counts())
            values.append(df[col].apply(lambda x: mapping.get(x)))

    values = pd.DataFrame(values)
    for i, c in enumerate(values.columns):
        sample = values[c]
        nonnull_idx = sample.first_valid_index()
        if nonnull_idx is not None:
            new_values[i] = sample.loc[nonnull_idx]
    new_values = pd.Series(new_values, index=df.index)
    new_values.fillna(default, inplace=True)
    return new_values


def _age_to_lifestage(df, mappings, default):
    norm_age = mappings['qiita_study_id']
    stages = mappings['lifestage']

    cols = {'qiita_study_id', }
    ages = set()
    for grp in norm_age.values():
        age, units = grp
        if age is None:
            continue

        ages.add(age)
        cols.add(age)
        if units is not None and \
                units not in ('YEARS', 'DAYS', 'WEEKS') and \
                not units.startswith('NULLUSE'):
            cols.add(units)
        if units is not None and units.startswith('NULLUSE'):
            cols.add(units.split(':', 1)[1])

    subset = df[list(cols)].copy()
    for c in ages:
        subset[c] = pd.to_numeric(subset[c], errors='coerce')

    def f(row):
        qid = row['qiita_study_id']

        age, units = norm_age.get(qid, (None, None))
        if age is None:
            # this is super dirty. 10352 has life_stage, uncontrolled
            # and lacks age, so for the moment. so if "age" is None,
            # we interpret "units" as the life stage.
            return units

        if units == 'DAYS':
            units = 'days'
        elif units == 'YEARS':
            units = 'years'
        elif units == 'WEEKS':
            units = 'weeks'
        elif units.startswith('NULLUSE'):
            col = units.split(':', 1)[1]
            return row[col].capitalize()
        else:
            units = row[units]

        age = row[age]
        if units == 'days':
            age = age / 365
        elif units == 'weeks':
            age = age / 52
        elif units == 'months':
            age = age / 12

        stage = default
        for label, (low, high) in stages.items():
            if low <= age < high:
                stage = label
                break

        return stage

    new_values = subset.apply(f, axis=1)
    new_values.fillna(default, inplace=True)
    return new_values


def _hard_remap(df, mapping):
    for study_id, country in mapping.items():
        df.loc[df['qiita_study_id'] == study_id, 'country'] = country


@cli.command(name="microbial-map")
@click.option('--input-output', type=click.Path(exists=True), required=True)
@click.option('--normalization', type=click.Path(exists=True), required=True)
def microbial_map(input_output, normalization):
    norm_details = json.loads(open(normalization).read())
    df = pd.read_csv(input_output, sep='\t', dtype=str).set_index('#SampleID')

    for norm_detail in norm_details:
        plotting_category = norm_detail['plotting_category']
        norm = norm_detail['normalization']
        default = norm['default']

        if 'explicit_mapping' in norm:
            _hard_remap(df, norm['explicit_mapping'])

        if 'remap_if_needed' in norm:
            new_values = _remap_if_needed(df, norm['remap_if_needed'], default)
        elif 'age_to_lifestage' in norm:
            new_values = _age_to_lifestage(df, norm['age_to_lifestage'],
                                           default)
        else:
            raise KeyError("Unknown norm: %s" % str(norm))

        df[plotting_category] = new_values
    df.to_csv(input_output, sep='\t', index=True, header=True)


def test_anonymize_fuzz_remove():
    df = pd.DataFrame([['foo', 'bar', 'baz'],
                       ['foo1', 'bar', 'baz1'],
                       ['foo2', 'bar1', 'baz2'],
                       ['foo3', 'bar1', 'baz3']],
                      columns=['#SampleID', 'country', 'latitude'])
    _anonymize_fuzz_remove(df, df)
    assert set(df['country']) == {'Removed', }
    assert set(df['latitude']) == {'Removed', }


def test_anonymize_fuzz_age():
    df = pd.DataFrame([['foo', '2', 'baz'],
                       ['foo1', 'not present', 'baz1'],
                       ['foo2', '30', 'baz2'],
                       ['foo3', '40', 'baz3']],
                      columns=['#SampleID', 'age', 'other'])
    _anonymize_fuzz_age(df, df)
    assert 'not present' in list(df['age'])
    assert not np.isclose(float(df.iloc[0, 1]), 2)
    assert not np.isclose(float(df.iloc[2, 1]), 30)
    assert not np.isclose(float(df.iloc[3, 1]), 40)

def test_anonymize_fuzz_bmi():
    df = pd.DataFrame([['foo', '2', 'baz'],
                       ['foo1', 'not present', 'baz1'],
                       ['foo2', '30', 'baz2'],
                       ['foo3', '40', 'baz3']],
                      columns=['#SampleID', 'bmi', 'other'])
    _anonymize_fuzz_bmi(df, df)
    assert 'not present' in list(df['bmi'])
    assert not np.isclose(float(df.iloc[0, 1]), 2)
    assert not np.isclose(float(df.iloc[2, 1]), 30)
    assert not np.isclose(float(df.iloc[3, 1]), 40)


def test_anonymize_sample_and_study():
    df = pd.DataFrame([['foo', 'bar', 'baz'],
                       ['foo1', 'bar', 'baz1'],
                       ['foo2', 'bar1', 'baz2'],
                       ['foo3', 'bar1', 'baz3']],
                      columns=['#SampleID', 'qiita_study_id', 'thing'])

    random_studies = set()
    _anonymize_sample_and_study(random_studies, df, df)

    assert list(df['thing']) == ['baz', 'baz1', 'baz2', 'baz3']
    assert 'foo' not in df['#SampleID']
    assert 'foo1' not in df['#SampleID']
    assert 'foo2' not in df['#SampleID']
    assert 'foo3' not in df['#SampleID']
    assert 'bar' not in df['qiita_study_id']
    assert 'bar1' not in df['qiita_study_id']


test_anonymize_sample_and_study()
test_anonymize_fuzz_remove()
test_anonymize_fuzz_age()
test_anonymize_fuzz_bmi()


if __name__ == '__main__':
    cli()
