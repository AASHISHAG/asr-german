# !/bin/bash

# Environment
ulimit -n 4096
module load singularity
export SINGULARITY_BINDPATH="/mnt"

# Working directory
cd /mnt/rds/redhen/gallina/home/axa1142

# Task
singularity exec -e --nv singularity-images/1.sif bash infer-vad.sh $1

# Receipt
echo -e "\n\tThe Deutsch ASR job is completed at: `date`\n"
