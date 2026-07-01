#!/bin/bash
#SBATCH --job-name=prokka\
#SBATCH --output=prokka_%j.out\
#SBATCH --error=prokka_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=100GB
#SBATCH --partition=standard
#SBATCH --time=08:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

# this must be run individually for each high quality bin you wish to annotate
prokka --outdir /path/to/prokka_output/bin1 --prefix annotation --kingdom Bacteria /path/to/bins_dir_SITE/bin.1.fa

echo "Ending: "`date +"%D %T"`
