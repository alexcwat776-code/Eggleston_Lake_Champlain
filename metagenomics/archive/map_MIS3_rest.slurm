#!/bin/bash
#SBATCH --job-name=map_MIS3_rest
#SBATCH --output=map_MIS3_rest_%j.out
#SBATCH --error=map_MIS3_rest_%j.err
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
mkdir -p mapped_MIS3
bowtie2 -p 16 -x megahit_MIS3/contigs_index -1 fastq/E514_S60_L001_R1_001.fastq.gz -2 fastq/E514_S60_L001_R2_001.fastq.gz -S mapped_MIS3/E514.sam
samtools view -bS mapped_MIS3/E514.sam | samtools sort -o mapped_MIS3/E514.bam
samtools index mapped_MIS3/E514.bam
rm mapped_MIS3/E514.sam
bowtie2 -p 16 -x megahit_MIS3/contigs_index -1 fastq/E523_S63_L001_R1_001.fastq.gz -2 fastq/E523_S63_L001_R2_001.fastq.gz -S mapped_MIS3/E523.sam
samtools view -bS mapped_MIS3/E523.sam | samtools sort -o mapped_MIS3/E523.bam
samtools index mapped_MIS3/E523.bam
rm mapped_MIS3/E523.sam
echo "Ending: "`date +"%D %T"`
