#!/bin/bash
#SBATCH --job-name=MAB_pipeline
#SBATCH --output=MAB_pipeline_%j.out
#SBATCH --error=MAB_pipeline_%j.err
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=85G
#SBATCH --cpus-per-task=16
#SBATCH --partition=long
#SBATCH --time=168:00:00
# ^ put your email here, and set the queue/memory/time to whatever your cluster uses
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh  # point this to wherever conda is installed on your machine
cd ~/Eggleston_Metagenomes  # cd into wherever you keep the project
conda activate Metagenomics_Eggleston_Lab
snakemake results/MAB/bins/.binning_done --cores 16 --printshellcmds --keep-going 2>&1
conda activate checkm
checkm data setRoot /home/achrostowski/.conda/envs/Metagenomics_Eggleston_Lab/checkm_data  # point this to your checkm data folder
rm -rf results/MAB/checkm
checkm lineage_wf --reduced_tree -x fa -t 16 --tab_table -f results/MAB/checkm_MAB_quality.tsv results/MAB/bins results/MAB/checkm 2>&1
