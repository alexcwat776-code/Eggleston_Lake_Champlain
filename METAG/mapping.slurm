#!/bin/bash
#SBATCH --job-name=mapping_SITE\
#SBATCH --output=mapping_SITE_%j.out\
#SBATCH --error=mapping_SITE_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=100GB
#SBATCH --partition=standard
#SBATCH --time=4:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

# you must create the output directory "mapped" and the nested directory for each site BEFORE running this script 
# (the tool cannot create directories), or the job will fail
INPUT_DIR="megahit_SITE"
OUTPUT_DIR="mapped"

# run this line only once for each site - it generates a database that can be used for all subsequent samples
bowtie2-build $INPUT_DIR/final.contigs.fa $INPUT_DIR/contigs_index

# run the following lines for EACH sample individually
# this tool is finicky and in my experience does not run successfully with for loops or copy and pasting the code for each sample
# in my experience, you just need to remake this script for each sample and run them individually (a pain, but it works)
# so for the first sample, run the full script, then comment out the bowtie2-build line for the remaining samples

bowtie2 -x $INPUT_DIR/contigs_index -1 fastq/file1.fq1 -2 fastq/file1.fq2 -S $OUTPUT_DIR/SITE/file1.sam 

samtools view -bS $OUTPUT_DIR/SITE/file1.sam | samtools sort -o $OUTPUT_DIR/SITE/file1.bam
samtools index $OUTPUT_DIR/SITE/file1.bam

# CAVEAT: if subsequent jobs fail, you can delete "contigs_index" and re-generate it for each job. Again a pain, but it works

echo "Ending: "`date +"%D %T"`
