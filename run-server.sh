#!/bin/bash

# Environment
ulimit -n 4096
module load singularity
export SINGULARITY_BINDPATH="/mnt"

# Working directory
cd /mnt/rds/redhen/gallina/home/axa1142

# Task
singularity exec singularity-images/kaldi_de.sif python kaldi/tools/kaldi-gstreamer-server/kaldigstserver/master_server.py --port=8888