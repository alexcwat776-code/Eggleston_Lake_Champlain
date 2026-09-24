#!/bin/bash
#SBATCH --job-name=genomad
#SBATCH --partition=long
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=/home/achrostowski/virome_out/genomad_%j.log
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=END,FAIL
# takes the contigs fasta and a sample label as arguments
# sbatch run_genomad.slurm ~/virome_out/renamed_contigs/E508_final.contigs.fa E508
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate virome
mkdir -p /home/achrostowski/virome_out/genomad/$2
genomad end-to-end "$1" /home/achrostowski/virome_out/genomad/$2 ~/virome_dbs/genomad_db --threads 16
