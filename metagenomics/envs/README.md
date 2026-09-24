# Envs

saved copies of the conda environments the metagenome pipeline uses. each file lists every tool and exact version, so you can rebuild the same setup instead of guessing.

## Files

```
Metagenomics_Eggleston_Lab.yml   main tools, megahit, bowtie2, samtools, metabat2, snakemake
checkm.yml                       checkm by itself, on python 3.9
prokka.yml                       prokka for gene annotation
anvio-9.yml                      anvi'o 9
```

## Rebuilding One

```
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh
conda env create -f Metagenomics_Eggleston_Lab.yml
conda activate Metagenomics_Eggleston_Lab
```

swap in whichever file you need. the scripts expect these exact environment names, so do not rename them.

*note, checkm is separate because it needs an older python than the main environment.

*note, do not install anything else into `anvio-9`, it breaks.

*note, checkm needs its reference data downloaded once, then set `checkm_data` in `../config.yaml` to wherever it ends up.

*note, if `conda env create` hangs on "Solving environment", use `mamba env create -f file.yml` instead (see the root readme).

## Saving a New One

if you install something new and want to save the environment the same way
```
conda activate environment_name
conda env export > envs/environment_name.yml
```
