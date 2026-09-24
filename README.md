# Eggleston Lake Champlain

multi omic analysis of cyanobacterial blooms in lake champlain. Eggleston Lab, Middlebury College.

every folder in here has its own readme that walks through what that part does step by step. this one covers the big picture and the setup you need before any of it works. if you are new, read this first, then go folder by folder.

## the big picture

we sample three spots on lake champlain. Missisquoi Bay (MIS) and St. Albans Bay (STA) both get cyanobacterial blooms most summers. Malletts Bay (MAB) does not, so it is the reference site the other two get compared against. sampling covers 2023 and 2024, which were both bloom years, and 2025, a drought year with no real bloom, which works like a natural experiment.

every water sample gets a number from the Eggleston Lab Sample Database, the "euro number" (like E508). that number is what ties everything together across all the data types, so keep it attached to every file you make.

the DNA from each sample gets sequenced a few different ways, and each one answers a different question
- 16S, which bacteria and cyanobacteria are there and how much of each
- 18S, which eukaryotes are there, so algae, protists, ciliates
- metagenomes, all the DNA in the sample at once, used to rebuild actual genomes
- viromes, the viruses, especially the ones that infect cyanobacteria

the plan is two papers. paper 1 describes who lives in the lake and how that changes by site and season, using all four data types. paper 2 zooms in on the cyanobacteria and what is different between bloom and non bloom conditions, including whether viruses play a role.

## whats in here

```
amplicons/             16S and 18S, start here for the amplicon data
  16S/                 16S processing scripts
  18S/                 18S processing scripts
metagenomics/          the metagenome pipeline we actually run now
  archive/             the first one off test scripts, kept around for reference
  envs/                saved conda environments so you can rebuild them exactly
METAG/                 Birch Klomparens' original metagenome scripts (her readme, not ours)
viromes/               finding and checking viruses in the metagenomes
```

raw sequencing files, databases, and results are not in here on purpose, they are way too big for github (see .gitignore). they live on ada and in the lab google drive.

## getting onto ada

ada is Middlebury's computing cluster, basically a big shared computer you log into remotely and send long jobs to.

1. get an ada account through Professor Eggleston and Middlebury IT. then log in from a terminal with your middlebury username and password

```
ssh username@ada
```

2. download VS Code and install the Remote SSH extension, then connect to ada through it. you get a file browser and an editor that are actually on ada, which is way easier than doing everything in the terminal. the terminal panel at the bottom of VS Code is also on ada once you are connected.

*note, if VS Code refuses to connect and the log says "Disk quota exceeded", you are out of storage on ada. log in with plain ssh from a normal terminal (`ssh username@ada.middlebury.edu`), delete big stuff you do not need, then try again. `du -sh ~/*` shows what is taking up space.

## conda environments

bioinformatics tools get installed into separate "environments" so they do not break each other. we use Professor Linderman's miniconda setup on ada, and every script in this repo starts by pointing at it

```
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda activate environment_name
```

the environments used across the repo
- dada2, everything for 16S and 18S
- Metagenomics_Eggleston_Lab, the metagenome tools
- checkm, checkm alone because it needs an older python
- prokka, gene annotation for genomes
- anvio-9, anvi'o, has to be in a totally clean environment or it breaks
- virome, genomad and checkv
- blast, for comparing sequences against a reference
- dram, for annotating viral genes

the metagenome ones are saved in `metagenomics/envs/` so you can rebuild them exactly, see the readme in there.

*note, if `conda create` sits on "Solving environment" for more than about 10 minutes it is stuck. kill it and use mamba instead, which is way faster. it lives in its own environment

```
conda create -n mamba_env -c conda-forge mamba -y
conda activate mamba_env
mamba create -n some_env -c bioconda -c conda-forge some_tool -y
```

## using SLURM

ada is shared, so you do not run big jobs directly. you write a small script saying how much memory and time you need, and SLURM queues it and runs it on a compute node. every `.slurm` file in this repo is one of these.

```
sbatch script_name.slurm     send a job
squeue -u username           see your jobs that are running or waiting
scancel job_ID               cancel a job
sacct -j job_ID --format=JobID,State,Elapsed,MaxRSS    check if a finished job worked
```

in `squeue`, PD means waiting and R means running. when a job disappears it is done, but not necessarily working, so check `sacct` and the log file.

*note, you have to be in the same folder as the script when you `sbatch` it, otherwise you get "Unable to open file". `cd` there first.

*note, every script has `achrostowski` paths and email in it. change those to your own before running anything.

## other commands you will use a lot

```
cd /path/to/folder    move into a folder
ls -la                list what is in the current folder
pwd                   print where you are
head file             show the first 10 lines of a file
cat file              print a whole (small) file
du -sh folder         how big is this folder
```

## getting data onto ada

sequencing files and the sequencing reports get stored in the lab google drive. keep the reports handy, they help when something looks off. files get onto ada by dragging them into the VS Code explorer or with rclone.

*note, samples are not always named the same way. the E400 to E409 samples were in the drive as `A.400.1` and so on, no E. if samples seem missing, search by the number, not the full name.

## people

- Professor Eggleston, PI
- Birch Klomparens, original metagenome pipeline (`METAG/`)
- Camilla Salwen, original 16S pipeline, bloom phase table, and corncob method (honors thesis, spring 2025)
- Kate Schroeder, extended amplicon code
- Irene Hu, earlier virome work
- Alex Chrostowski, amplicon rebuild, metagenome pipeline, virome pipeline
