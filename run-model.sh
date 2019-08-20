#!/bin/bash

# Environment
ulimit -n 4096
module load singularity
export SINGULARITY_BINDPATH="/mnt"

# Working directory
cd /mnt/rds/redhen/gallina/home/axa1142/kaldi/tools/kaldi-gstreamer-server

# Task
singularity exec -e --nv ../../../singularity-images/test_kaldi.sif python kaldigstserver/client.py -r 32000 --save-adaptation-state adaptation-state.json $1