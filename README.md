# Eggleston Lake Champlain

multi omic analysis of cyanobacterial blooms in lake champlain. Eggleston Lab, Middlebury College.

every folder has its own readme with the steps for that part. this one covers the big picture and setup.

## The Big Picture

we sample three spots on lake champlain, Missisquoi Bay (MIS), St. Albans Bay (STA), and Malletts Bay (MAB). MAB is the reference site the other two get compared against.

every sample gets a number from the Eggleston Lab Sample Database, the "euro number" (like E508). that number ties everything together across the data types, so keep it on every file you make.

the DNA from each sample gets sequenced a few ways
- 16S, bacteria and cyanobacteria
- 18S, eukaryotes like algae, protists, and ciliates
- metagenomes, all the DNA in the sample, used to rebuild genomes
- viromes, the viruses, especially the ones that infect cyanobacteria

the plan is two papers. paper 1 describes who lives in the lake and how that changes by site and season, using all four data types. paper 2 focuses on the cyanobacteria and bloom vs non bloom conditions, including whether viruses play a role.

## Whats In Here

```
amplicons/             16S and 18S
  16S/                 16S processing scripts
  18S/                 18S processing scripts
metagenomics/          the metagenome pipeline
  archive/             the first test scripts, kept around for reference
  envs/                saved conda environments
METAG/                 Birch Klomparens' original metagenome scripts
viromes/               finding and checking viruses in the metagenomes
```

raw sequencing files, databases, and results are not in here, they are too big for github (see .gitignore). they are on ada and in the lab google drive.

## Getting Onto Ada

1. get an ada account through Professor Eggleston and Middlebury IT, then log in
```
ssh username@ada
```
2. install VS Code with the Remote SSH extension and connect to ada through it

*note, if VS Code will not connect and the log says "Disk quota exceeded", you are out of storage on ada. log in with plain ssh (`ssh username@ada.middlebury.edu`), clear space (`du -sh ~/*` shows what is big), then try again.

## Conda Environments

every script starts by pointing at Professor Linderman's miniconda setup on ada
```
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate environment_name
```

the environments used across the repo
- dada2, 16S and 18S
- Metagenomics_Eggleston_Lab, the metagenome tools
- checkm, on its own because it needs an older python
- prokka, gene annotation
- anvio-9, anvi'o, has to stay in a clean environment
- virome, genomad and checkv
- blast, comparing sequences against a reference
- dram, annotating viral genes

the metagenome ones are saved in `metagenomics/envs/` so you can rebuild them exactly.

*note, if `conda create` sits on "Solving environment" for more than about 10 minutes it is stuck. kill it and use mamba instead, which lives in its own environment
```
conda create -n mamba_env -c conda-forge mamba -y
conda activate mamba_env
mamba create -n some_env -c bioconda -c conda-forge some_tool -y
```

## Using SLURM

every `.slurm` file in this repo is a job you send to ada's queue with `sbatch`
```
sbatch script_name.slurm     send a job
squeue -u username           see your running or waiting jobs
scancel job_ID               cancel a job
sacct -j job_ID --format=JobID,State,Elapsed,MaxRSS    check if a finished job worked
```

*note, `cd` into the folder with the script before you `sbatch` it, otherwise you get "Unable to open file".

*note, every script has `achrostowski` paths and email in it. change those to your own before running anything.

## Getting Data Onto Ada

sequencing files and reports are in the lab google drive. move them onto ada by dragging them into the VS Code explorer or with rclone.

*note, samples are not always named the same way. the E400 to E409 samples were in the drive as `A.400.1` and so on, no E. if samples seem missing, search by the number, not the full name.
