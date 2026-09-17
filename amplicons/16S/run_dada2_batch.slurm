#!/bin/bash
#SBATCH --job-name=dada2
#SBATCH --output=dada2_%j.out
#SBATCH --error=dada2_%j.err
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=long
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00

# takes the batch name as an argument
# sbatch run_dada2_batch.slurm run1
BATCH=$1
if [ -z "$BATCH" ]; then
  echo "usage: sbatch run_dada2_batch.slurm <run1|summer24|old508|new589>"
  exit 1
fi

# point this at wherever conda is installed on your machine
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate dada2

# cd into wherever you keep the project
cd /home/achrostowski/amplicon_16S_all

Rscript dada2_batch.R "$1" "$2"