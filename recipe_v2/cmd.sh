#!/bin/bash

# This script is adapted from swbd Kaldi run.sh (https://github.com/kaldi-asr/kaldi
# Copyright 2018 Kaldi developers (see: https://github.com/kaldi-asr/kaldi/blob/master/COPYING)
# Change GPU and G2P path accordingly

export train_cmd="utils/run.pl"
export decode_cmd="utils/run.pl"
export cuda_cmd="utils/run.pl -l gpu=1"
export sequitur_g2p="/usr/aashish/g2p/g2p.py"

export nJobs=28
export nDecodeJobs=12