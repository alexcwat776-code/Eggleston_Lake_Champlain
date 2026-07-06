#!/bin/bash
#SBATCH --job-name=checkm_MIS3
#SBATCH --output=checkm_MIS3_%j.out
#SBATCH --error=checkm_MIS3_%j.err
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=80G
#SBATCH --cpus-per-task=16
#SBATCH --partition=standard
#SBATCH --time=12:00:00
echo "Job ID: ${SLURM_JOB_ID}"
echo "Node: ${SLURMD_NODENAME}"
echo "Starting: "`date +"%D %T"`
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate checkm
cd ~/Eggleston_Metagenomes
checkm data setRoot ~/.conda/envs/Metagenomics_Eggleston_Lab/checkm_data
checkm lineage_wf --reduced_tree -x fa -t 16 --tab_table -f checkm_MIS3_quality.tsv bins_MIS3 checkm_MIS3
echo "Ending: "`date +"%D %T"`
