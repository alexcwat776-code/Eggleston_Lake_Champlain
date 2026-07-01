#!/bin/bash
#SBATCH --job-name=FASTQC
#SBATCH --output=FASTQC_%j.out
#SBATCH --error=FASTQC_%j.err
#SBATCH --mail-user=user@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=32GB
#SBATCH --partition=standard
#SBATCH --time=02:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

FORWARD="forward_reads.fq"
REVERSE="reverse_reads.fq"

OUTPUT_DIR="FASTQC_output"
mkdir -p $OUTPUT_DIR

fastqc $FORWARD $REVERSE --outdir=$OUTPUT_DIR

echo "Ending: "`date +"%D %T"`
