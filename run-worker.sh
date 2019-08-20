#!/bin/bash

# Environment
ulimit -n 4096
module load singularity
export SINGULARITY_BINDPATH="/mnt"

# Working directory
cd /mnt/rds/redhen/gallina/home/axa1142/kaldi/tools/kaldi-gstreamer-server

# Task
singularity exec -e --nv ../../../singularity-images/kaldi_de.sif bash run_kaldi_de.sh