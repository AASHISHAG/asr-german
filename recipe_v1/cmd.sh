#!/bin/bash

# This script is adapted from swbd Kaldi run.sh (https://github.com/kaldi-asr/kaldi

export train_cmd="utils/run.pl"
export decode_cmd="utils/run.pl"
export cuda_cmd="utils/run.pl -l gpu=1"
export sequitur_g2p="/usr/aashish/g2p/g2p.py"

export nJobs=4
export nDecodeJobs=2