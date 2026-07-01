#!/bin/bash
#SBATCH --job-name=trimmomatic_SITE
#SBATCH --output=trimmomatic_SITE_%j.out
#SBATCH --error=trimmomatic_SITE_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=50GB
#SBATCH --partition=standard
#SBATCH --time=04:00:00

echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}" 
echo "Starting: $(date +"%D %T")"

# list of sample IDs based on the names of your fastq files, by site
samples=(file1 file2 file3)

# this for loop will run all samples in the above list, provided your naming scheme matches
for sample in "${samples[@]}"; do
  echo "Processing sample $sample"
  trimmomatic PE \
    -threads 8 \
    fastq/${sample}.fq1 fastq/${sample}.fq2 \
    fastq/${sample}.trimmed.paired.fq1 fastq/${sample}.trimmed.unpaired.fq1 \
    fastq/${sample}.trimmed.paired.fq2 fastq/${sample}.trimmed.unpaired.fq2 \
    SLIDINGWINDOW:4:20 \
    MINLEN:50
done

echo "Ending: $(date +"%D %T")"
