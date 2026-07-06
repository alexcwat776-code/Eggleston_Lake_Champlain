#!/bin/bash
#SBATCH --job-name=megahit_E508
#SBATCH --output=megahit_E508_%j.out
#SBATCH --error=megahit_E508_%j.err
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=85G
#SBATCH --cpus-per-task=16
#SBATCH --partition=standard
#SBATCH --time=24:00:00
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}"
echo "Starting: "`date +"%D %T"`
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate Metagenomics_Eggleston_Lab
cd ~/Eggleston_Metagenomes
megahit -1 fastq/E508_S57_L001_R1_001.fastq.gz -2 fastq/E508_S57_L001_R2_001.fastq.gz -o megahit_E508 --min-contig-len 1500 --min-count 3 --no-mercy -m 80000000000 -t 16
echo "Ending: "`date +"%D %T"`
