#!/bin/bash
#SBATCH --job-name=dada2_18S
#SBATCH --partition=long
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/achrostowski/amplicon_18S_all/dada2_%j.log
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=END,FAIL
# takes the batch name and mode as arguments
# sbatch run_dada2_18S.slurm concat23 paired
# point this at wherever conda is installed on your machine
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate dada2
# cd into wherever you keep the project
cd /home/achrostowski/amplicon_18S_all
Rscript dada2_batch_18S.R "$1" "$2"