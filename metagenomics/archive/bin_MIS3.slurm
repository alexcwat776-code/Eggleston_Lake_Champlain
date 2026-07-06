#!/bin/bash
#SBATCH --job-name=bin_MIS3
#SBATCH --output=bin_MIS3_%j.out
#SBATCH --error=bin_MIS3_%j.err
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
mkdir -p bins_MIS3
jgi_summarize_bam_contig_depths --outputDepth bins_MIS3/depth.txt mapped_MIS3/E508.bam mapped_MIS3/E514.bam mapped_MIS3/E523.bam
metabat2 -i megahit_MIS3/final.contigs.fa -a bins_MIS3/depth.txt -o bins_MIS3/bin -t 16 -m 1500
echo "Ending: "`date +"%D %T"`
