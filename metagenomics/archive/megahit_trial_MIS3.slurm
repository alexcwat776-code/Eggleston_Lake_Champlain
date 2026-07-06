#!/bin/bash
#SBATCH --job-name=megahit_MIS3
#SBATCH --output=megahit_MIS3_%j.out
#SBATCH --error=megahit_MIS3_%j.err
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
megahit -1 fastq/E508_S57_L001_R1_001.fastq.gz,fastq/E514_S60_L001_R1_001.fastq.gz,fastq/E523_S63_L001_R1_001.fastq.gz -2 fastq/E508_S57_L001_R2_001.fastq.gz,fastq/E514_S60_L001_R2_001.fastq.gz,fastq/E523_S63_L001_R2_001.fastq.gz -o megahit_MIS3 --min-contig-len 1500 --min-count 3 --no-mercy -m 80000000000 -t 16
echo "Ending: "`date +"%D %T"`
