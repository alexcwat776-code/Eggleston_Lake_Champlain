# 18S processing

turns raw 18S reads into one clean table of named ASVs across 213 samples (E417 to E672). 18S picks up eukaryotes, so algae, diatoms, ciliates, fungi, and other protists. same idea as 16S with a few differences, called out below. the ada steps run in the `dada2` conda environment. see `../README.md` (the amplicons overview) for the bigger picture.

## files

```
dada2_batch_18S.R        cleans up one sequencing batch
run_dada2_18S.slurm      sends dada2_batch_18S.R to SLURM
merge_batches_18S.R      merges all batches, filters by length, assigns taxonomy
run_merge_18S.slurm      sends merge_batches_18S.R to SLURM
BuildFile_v2.R           builds the eukaryote reference used for naming ASVs
18SPostProcessing.Rmd    figures, stats, and corncob, run in RStudio
```

the metadata table comes from `../16S/build_metadata.R`, both use the same one.

## 1. build the eukaryote reference, BuildFile_v2.R

takes the SILVA 138.2 database, keeps only the eukaryotes, and trains a reference out of them that step 3 uses to name ASVs. only needs to run once.

*note, this is its own thing from the 16S reference. the 16S one has no eukaryotes, the 18S one has no bacteria, so never swap them.

## 2. clean up each batch, dada2_batch_18S.R

same as 16S. cut primers, trim bad read ends, throw out low quality reads, fix sequencing errors, join forward and reverse reads, save quality plots.

run it once per batch
```
sbatch run_dada2_18S.slurm concat23 paired
sbatch run_dada2_18S.slurm egg23 paired
sbatch run_dada2_18S.slurm summer24 paired
sbatch run_dada2_18S.slurm old508 paired
sbatch run_dada2_18S.slurm new589 paired
```

the batches
- concat23, 23 samples from 2023 pooled from two sequencing runs
- egg23, 10 samples from 2023, same folder as concat23, told apart by file name
- summer24, E490 to E507
- old508, E508 to E588
- new589, E589 onward

outputs, in `dada2_out_paired/` ->
- `seqtab_BATCH.rds`, the ASV table for that batch
- `track_BATCH.csv`, how many reads survived each step per sample
- `quality_BATCH.pdf` and `errors_BATCH.pdf`, the plots

*note, the 18S primers and trim settings are different from 16S, do not copy them over.

*note, sample E461 has no reverse read file anywhere, so it gets skipped automatically.

*note, check `track_BATCH.csv` after every batch same as 16S. if "merged" is way lower than "filtered", the reads are not overlapping.

## 3. merge and assign taxonomy, merge_batches_18S.R

once every batch is done, this
1. stitches all the batch tables into one
2. removes chimeras, fake sequences made by accident during copying
3. keeps only ASVs between 365 and 448 base pairs, anything shorter is a bad join
4. names every ASV using the reference from step 1

```
sbatch run_merge_18S.slurm paired
```

outputs, in `dada2_out_paired/` ->
- `ASVs_counts_18S_ALL.csv`, how many reads of each ASV in each sample
- `ASVs_taxonomy_18S_ALL.csv`, what each ASV is
- `ASVs_18S_ALL.fa`, the DNA sequence of each ASV
- `seqtab_lenfilt_ALL.rds` and `taxid_matrix_ranked.rds`, the same tables in R format

*note, the E400 to E409 samples are left out of 18S on purpose. their reads came from a different facility and do not line up with the rest.

*note, 18S names go domain, kingdom, phylum, class, order, family, genus. no species. expect a lot of ASVs to come back unnamed below class, eukaryote references are just thinner than bacterial ones.

## 4. figures, stats, and corncob, 18SPostProcessing.Rmd

download the three csvs and the metadata csv from ada, then open this in RStudio. what it does is laid out in `../README.md` (the amplicons overview).
