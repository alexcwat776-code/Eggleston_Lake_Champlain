#!/bin/bash
#SBATCH --job-name=STA_pipeline
#SBATCH --output=STA_pipeline_%j.out
#SBATCH --error=STA_pipeline_%j.err
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
snakemake results/STA/bins/.binning_done --cores 16 --printshellcmds --keep-going 2>&1
conda activate checkm
checkm data setRoot /home/achrostowski/.conda/envs/Metagenomics_Eggleston_Lab/checkm_data  # point this to your checkm data folder
rm -rf results/STA/checkm
checkm lineage_wf --reduced_tree -x fa -t 16 --tab_table -f results/STA/checkm_STA_quality.tsv results/STA/bins results/STA/checkm 2>&1
