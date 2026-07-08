# Eggleston_Lake_Champlain
This repo holds the code for looking at cyanobacterial blooms in Lake Champlain across three sites (MIS, STA, MAB). The metagenomics folder has my pipeline (Alex Chrostowski) for turning shotgun reads into MAGs, built as a Snakemake workflow with the SLURM scripts that run each step, and it follows the workflow doc in the Eggleston Lab Google Drive called "Metagenomic Analysis. Protocol, Code, and Workflow." The METAG folder is Birch Klomparens' original pipeline. Read the comments in each script before you run it, since they mark the lines you need to change for your own setup like your conda path, your cluster settings, and your sample names. The big data files are not in here since github can't hold them, so they live on the cluster and in the lab Google Drive. Questions, email me at alexcwat776@gmail.com

What is in this Repository: 

The metagenomics folder has the pipeline, built as a Snakemake workflow with the SLURM scripts that run each step. The metagenomics/envs folder has the conda environments as yaml files so you can rebuild the same tools. The metagenomics/archive folder has older trial scripts, kept for reference but not needed to run anything. The METAG folder is Birch Klomparens' original pipeline.


Workflow:
The pipeline goes from raw reads to finished MAGs. The full step by step writeup lives in the Google Drive doc. The short version is

1. check read quality with fastqc
2. assemble each site's reads into contigs with megahit
3. map reads back to the contigs to get coverage
4. bin the contigs into draft genomes with metabat2
5. score each bin with checkm, where high quality is above 90 percent complete and under 5 percent contamination
6. annotate the genes with prokka
7. refine and view the bins in anvi'o

Most of this is wrapped in the Snakemake workflow (Snakefile and config.yaml), so you set your samples and sites in the config and the pipeline runs the steps in order. The run scripts (run_MIS.slurm, run_STA.slurm, run_MAB.slurm) produce for each site.


What you need to change:
Read the comments in each script before you run it. A few lines show up in most scripts that you have to configure for your own setup.
#Your email at the top of each SLURM script
#SBATCH --mail-user=you@youremail.com
#The cluster settings, since queue names and limits differ by cluster
#SBATCH --partition=long
#SBATCH --mem=85G #MAKE SURE TO ALLOCATE A PROPER AMOUNT. MORE ALLOCATION THAN PERMITTED FOR IND. USERS RESULTS IN OOM.
#SBATCH --time=168:00:00 #LIKEWISE WITH TIME. 

#The conda line, pointed at wherever conda lives on your machine
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
#Your samples and sites in config.yaml, where the left side is the sample id and the right side is the fastq file name before the R1 and R2 part
sites:
  MIS:
    E508: "E508_S57_L001"
    E514: "E514_S60_L001"

    
Running it:
Once the config and scripts are set for your setup, submit the run script for a site with sbatch:
sbatch run_MIS.slurm


Data
The big files (reads, bam files, databases) are not in here since github can't hold them. They live on the cluster and in the lab Google Drive.
Questions, email me at alexcwat776@gmail.com

