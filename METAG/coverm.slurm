#!/bin/bash
#SBATCH --job-name=coverm\
#SBATCH --output=coverm_%j.out\
#SBATCH --error=coverm_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=100GB
#SBATCH --partition=standard
#SBATCH --time=24:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

# copy and paste the following code chunk for each trimmed and paired .fastq file, as shown below:

coverm genome \
  --coupled fastq/file1.trimmed.paired.fq1 fastq/file1.trimmed.paired.fq2 \ # this part changes (fastq files)
  --genome-fasta-files \ # this whole part stays the same (ALL high quality bins)
# below, you must manually enter the ID numbers of the high quality bins you recorded based on checkM results
# in the first line, write all high quality MIS bins, STA in the next, and MAB in the final line
    bins_dir_SITE/bin.ID.fa bins_dir_SITE/bin.ID.fa \
    bins_dir_SITE/bin.ID.fa bins_dir_SITE/bin.ID.fa \
    bins_dir_SITE/bin.ID.fa bins_dir_SITE/bin.ID.fa \
  -t 8 \
  -m mean relative_abundance covered_fraction \
  -o coverm_output/file1.tsv 

coverm genome \
  --coupled fastq/file2.trimmed.paired.fq1 fastq/file2.trimmed.paired.fq2 \
  --genome-fasta-files \
# the lines below should match the chunk above (map the same high quality bins to a new file for relative community composition)
    bins_dir_SITE/bin.ID.fa bins_dir_SITE/bin.ID.fa \
    bins_dir_SITE/bin.ID.fa bins_dir_SITE/bin.ID.fa \
    bins_dir_SITE/bin.ID.fa bins_dir_SITE/bin.ID.fa \
  -t 8 \
  -m mean relative_abundance covered_fraction \
  -o coverm_output/file2.tsv

# continue for all fastq files, changing ONLY file names, NOT bins

echo "Ending: "`date +"%D %T"`
