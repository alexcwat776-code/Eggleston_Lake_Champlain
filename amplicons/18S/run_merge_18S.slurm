#!/bin/bash
#SBATCH --job-name=merge18S
#SBATCH --partition=long
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --output=/home/achrostowski/amplicon_18S_all/merge_%j.log
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=END,FAIL
# point this at wherever conda is installed on your machine
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate dada2
# cd into wherever you keep the project
cd /home/achrostowski/amplicon_18S_all
Rscript merge_batches_18S.R "$1"