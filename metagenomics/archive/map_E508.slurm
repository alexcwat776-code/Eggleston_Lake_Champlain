#!/bin/bash
#SBATCH --job-name=map_E508
#SBATCH --output=map_E508_%j.out
#SBATCH --error=map_E508_%j.err
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=40G
#SBATCH --cpus-per-task=16
#SBATCH --partition=standard
#SBATCH --time=4:00:00
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}"
echo "Starting: "`date +"%D %T"`
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate Metagenomics_Eggleston_Lab
cd ~/Eggleston_Metagenomes
mkdir -p mapped
bowtie2-build megahit_E508/final.contigs.fa megahit_E508/contigs_index
bowtie2 -p 16 -x megahit_E508/contigs_index -1 fastq/E508_S57_L001_R1_001.fastq.gz -2 fastq/E508_S57_L001_R2_001.fastq.gz -S mapped/E508.sam
samtools view -bS mapped/E508.sam | samtools sort -o mapped/E508.bam
samtools index mapped/E508.bam
rm mapped/E508.sam
echo "Ending: "`date +"%D %T"`
