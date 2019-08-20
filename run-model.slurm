# !/bin/bash

# Resources
# SBATCH --nodes=1
# SBATCH --cpus-per-task=1
# SBATCH --time=2:00:00
# SBATCH -p gpu -C gpuk40 --mem=100gb --gres=gpu:2 

# Requeue in case of a node faiure
# SBATCH --requeue

# Title
# SBATCH --job-name="Chinese_ASR"

# Environment
ulimit -n 4096
module load singularity
export SINGULARITY_BINDPATH="/mnt"

# Working directory
cd /mnt/rds/redhen/gallina/home/axa1142

# Task
singularity exec -e --nv singularity-images/test_kaldi.sif bash infer.sh $1

# Receipt
echo -e "\n\tThe Deutsch ASR job is completed at: `date`\n"
