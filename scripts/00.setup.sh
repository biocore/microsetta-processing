#!/bin/bash

# NOTE: assumes a standard qiime2-2019.10 environment exists
source ./util.sh

conda install -y -c conda-forge cartopy redbiom deicode songbird
pip install https://github.com/nbokulich/q2-coordinates/archive/master.zip

# NOTE: per q2-coordinates installation
pip install pysal==2.0rc2

