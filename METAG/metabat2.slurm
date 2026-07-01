#!/bin/bash
#SBATCH --job-name=metabat2_SITE\
#SBATCH --output=metabat2_SITE_%j.out\
#SBATCH --error=metabat2_SITE_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=100GB
#SBATCH --partition=standard
#SBATCH --time=24:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

metabat2 -i megahit_SITE/final.contigs.fa -a mapped/SITE/metabat_depth.txt -o bins_dir/bin
# metabat2 does not allow you to create an output directory, you can organize output after bins are generated
# for my workflow, I rename the generated output directory as so: bins_dir_SITE

echo "Ending: "`date +"%D %T"`
