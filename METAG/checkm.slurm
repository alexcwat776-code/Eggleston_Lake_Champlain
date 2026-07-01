#!/bin/bash
#SBATCH --job-name=checkm_SITE\
#SBATCH --output=checkm_SITE_%j.out\
#SBATCH --error=checkm_SITE_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=100GB
#SBATCH --partition=standard
#SBATCH --time=10:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

checkm lineage_wf bins_dir_SITE/ checkm_out_MIS/ -x fa

echo "Ending: "`date +"%D %T"`
