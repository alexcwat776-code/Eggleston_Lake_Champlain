#!/bin/bash
#SBATCH --job-name=checkv
#SBATCH --partition=long
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --output=/home/achrostowski/virome_out/checkv_%j.log
#SBATCH --mail-user=achrostowski@middlebury.edu
#SBATCH --mail-type=END,FAIL
# takes a sample label as an argument, expects genomad already ran for it
# sbatch run_checkv.slurm E508
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate virome
mkdir -p /home/achrostowski/virome_out/checkv/$1
checkv end_to_end /home/achrostowski/virome_out/genomad/$1/*_summary/*_virus.fna \
  /home/achrostowski/virome_out/checkv/$1 -t 16 -d ~/virome_dbs/checkv_db
