# microsetta-processing
Processing scripts for The Microsetta Initiative

# What is this?

This repository houses the scripts that process Microsetta data. The output from processing can be served by the `microsetta-public-api`, allowing participants to access and explore their data. These outputs include alpha and beta diversity, as well as taxonomy details.

# Install

The processing scripts depend on a standard QIIME 2 [environment](https://docs.qiime2.org/2020.11/install/native/#install-qiime-2-within-a-conda-environment), and [redbiom](https://github.com/biocore/redbiom), and assume a Torque/PBS submission environment.

# To run

A set of environment variables control the processing:

- `$QIIME_VERSION` is used on `conda activate` (e.g., 2020.11). [REQUIRED]
- `$EMAIL` is a contact email to specify on job submission. [OPTIONAL]
- `$TMI_NAME` is a shortname for the processing run (e.g., tmi-gut-16S) [REQUIRED]
- `$TMI_TITLE` is a human readable longname (e.g., "Microsetta fecal 16S data") [REQUIRED]
- `$TMI_DATATYPE` specifies whether to process 16S or WGS [REQUIRED]
- `$STUDIES` contains a dot delimited list of Qiita study IDs to process. For example, "10317.850"is the combination of the American Gut (Microsetta) data and the data from Yatsunenko et al Nature 2012. [REQUIRED]
- `$ENV_PACKAGE` contains a dot delimited list of EBI `env_package` values to process (e.g., "human-gut") [REQUIRED]
- `$AG_DEBUG`, if set to true, limits processing to 1000 samples [OPTIONAL]
- `$TMI_WEIGHTED_UNIFRAC`, if set, compute weighted unifrac in addition to unweighted [OPTIONAL]
- `$TMI_SINGLE_SUBJECT`, if set, provide various outputs over an individual subject rather than all samples [OPTIONAL]

If running `submit_all.sh` directly, or one of the individual scripts, it is necessary to specify the above required environment variables.

Alternatively, the `reprocess.sh` script can be used which sets many of the variables above followed by executing `submit_all.sh`. If using `reprocess.sh`, it is still necessary to indicate `$QIIME_VERSION`. 
