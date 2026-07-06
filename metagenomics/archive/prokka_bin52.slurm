#!/bin/bash
#SBATCH --job-name=prokka_bin52
#SBATCH --output=prokka_bin52_%j.out
#SBATCH --error=prokka_bin52_%j.err
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=40G
#SBATCH --cpus-per-task=16
#SBATCH --partition=standard
#SBATCH --time=2:00:00
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}"
echo "Starting: "`date +"%D %T"`
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate prokka
cd ~/Eggleston_Metagenomes
mkdir -p prokka_MIS3
prokka --force --outdir prokka_MIS3/bin52 --prefix bin52 --kingdom Bacteria --metagenome --cpus 16 bins_MIS3/bin.52.fa
echo "Ending: "`date +"%D %T"`
