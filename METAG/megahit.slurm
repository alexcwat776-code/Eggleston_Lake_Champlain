#!/bin/bash
#SBATCH --job-name=megahit_SITE\
#SBATCH --output=megahit_SITE_%j.out\
#SBATCH --error=megahit_SITE_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=200GB # fix
#SBATCH --partition=long
#SBATCH --time=168:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

INPUT_DIR="fastq" # directory where concatenated .fastq files are stored
OUTPUT_DIR="megahit_SITE" # create this before running?

megahit -1 $INPUT_DIR/SITE.fq1 -2 $INPUT_DIR/SITE.fq2 \ # input forward and reverse files for a single site
    -o $OUTPUT_DIR \
    --min-contig-len 1500 \
    --min-count 3 \
    --no-mercy

echo "Ending: "`date +"%D %T"`

# Re-run this script for each site (MIS, STA, MAB) and respective .fastq files
