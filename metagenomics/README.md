# metagenomics

for metagenomes the sequencing center sequenced all the DNA in each sample, not just one gene. the goal is to rebuild actual genomes of the organisms in the lake, called MAGs (metagenome assembled genomes).

this used to be a set of scripts run one at a time by hand (Birch's version, in `../METAG/`). now it is a snakemake pipeline, which runs every step in order and skips anything already done, so if a job dies you can rerun it and it picks up where it left off.

runs on ada from a folder called `~/Eggleston_Metagenomes`. see the root readme for ada, conda, and SLURM basics.

## files

```
Snakefile                the pipeline, every step and how they connect
config.yaml              which samples go with which site, plus settings
run_MIS.slurm            runs the pipeline for MIS
run_STA.slurm            same for STA
run_MAB.slurm            same for MAB
make_quality_table.sh    labels and sorts bins by quality
run_anvio_site.slurm     builds anvi'o databases for a site
launch_anvio.sh          opens anvi'o in your browser
ARTIFACT_MANIFEST.txt    list of what the pipeline made and where it is
archive/                 the first test scripts, see the readme in there
envs/                    saved conda environments, see the readme in there
```

## 1. set up, config.yaml

put the raw `.fastq.gz` files in `~/Eggleston_Metagenomes/fastq/`, then list which samples go with which site in `config.yaml`. left side is the sample number, right side is the start of the file name before `_R1_001.fastq.gz`
```
MIS:
  E508: "E508_S57_L001"
```

each site gets pooled into one assembly, 11 samples for MIS, 11 for STA, 10 for MAB. pooling gives the assembler more to work with than any one sample would.

*note, change the conda environment names and the checkm data path in `config.yaml` to your own.

## 2. run the pipeline, run_MIS.slurm / run_STA.slurm / run_MAB.slurm

```
cd ~/Eggleston_Metagenomes
sbatch run_MIS.slurm
```

one per site, they can all run at once. each asks for 168 hours since assembly can take days. in order it runs
- megahit, stitches overlapping reads into longer pieces of DNA called contigs -> `results/SITE/megahit/final.contigs.fa`
- bowtie2 and samtools, lines each sample's reads back up to the contigs to see how much of each contig is in each sample -> `results/SITE/mapped/SAMPLE.bam`
- jgi_summarize_bam_contig_depths, turns that into one coverage table -> `results/SITE/bins/depth.txt`
- metabat2, groups contigs that probably came from the same organism into bins (draft genomes) -> `results/SITE/bins/`
- checkm, grades each bin on how complete it is and how much other DNA got mixed in -> `results/SITE/checkm_SITE_quality.tsv`

*note, the site scripts run snakemake up to binning, then run checkm separately in its own environment. so the quality table is `results/SITE/checkm_SITE_quality.tsv`, not the `checkm/quality_report.tsv` the Snakefile mentions.

*note, if you ever rerun megahit by hand, delete its output folder first or it just stops.

*note, do not delete the `mapped/` folders, anvi'o needs the `.bam` files.

## 3. sort bins by quality, make_quality_table.sh

run it directly, not with sbatch
```
bash make_quality_table.sh MIS
```

labels every bin
- HIGH, 90% or more complete and under 5% contaminated
- MEDIUM, 50% or more complete and under 10% contaminated
- LOW, everything else

output -> `results/SITE/checkm_SITE_quality_SORTED.txt`

results so far, 185 bins at MIS, 126 at STA, 121 at MAB (432 total). only 7 are high quality, which is normal for lake water. one of the 7 is a cyanobacterium and it came from MAB, the non bloom site.

*note, checkm also guesses what each bin is, but those names are rough. trust the completeness and contamination numbers, not the names.

## 4. anvi'o, run_anvio_site.slurm and launch_anvio.sh

anvi'o lets you look at bins and clean them up by hand in a browser. first build the databases for a site, which also pulls in the metabat2 bins
```
sbatch run_anvio_site.slurm MIS
```

output -> `anvio_SITE/CONTIGS.db` and `anvio_SITE/MERGED-PROFILE/PROFILE.db`

then to open it, run this directly, not with sbatch
```
bash launch_anvio.sh MIS
```

each site gets its own port, MIS 8080, STA 8081, MAB 8082. in VS Code go to the PORTS tab, forward that port, open `http://localhost:8080` in chrome, and click draw.

*note, keep the `anvio-9` environment for anvi'o only, installing anything else into it breaks it.

## 5. gene annotation, prokka

prokka finds the genes in a genome and guesses what each one does. so far it has only been run on one high quality bin, `archive/prokka_bin52.slurm`. to run it on another bin, copy that script and change the bin name. Birch's `../METAG/` has the fuller version, including circular genome pictures with CGView.

## viromes

the virus work runs on these same assemblies (`results/SITE/megahit/final.contigs.fa`), see `../viromes/`.
