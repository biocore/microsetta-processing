# Processing 

Full processing assumes a SLURM cluster with sufficient resources, a standard QIIME 2 2022.2 environment, and writable access to a directory called `/projects/tmi-public-results`. Assuming these conditions are met, the following should work:

```
git clone https://github.com/biocore/microsetta-processing.git
conda activate qiime2-2022.2
pip install redbiom
cd microsetta-processing/scripts
bash reprocess.sh
```

If the submitting user has a `~/.forward` set, emails will be sent to the forwarding address in the event of a failure.

Logs can be found under `microsetta-processing/logs`.

Results can be found under `microsetta-processing/results`.

On successful processing completion, a timestamped directory will be created under `/projects/tmi-public-results` including an `api-config.json` file compatible with `microsetta-public-api`.

# Deployment

On the production webserver, assuming `/projects/tmi-public-results` is mounted, restart the `microsetta-public-api` using the newly created `api-config.json`. 
