# 16S processing

turns raw 16S reads into one clean table of named ASVs across all 251 samples (E400 to E672). the ada steps run in the `dada2` conda environment. see `../README.md` (the amplicons overview) for the bigger picture.

## files

```
build_metadata.R             builds the sample info table from the lab sample database
dada2_batch.R                cleans up one sequencing batch
run_dada2_batch.slurm        sends dada2_batch.R to SLURM
merge_batches.R              merges all batches and assigns taxonomy
run_merge.slurm              sends merge_batches.R to SLURM
qc_16S.R                     sanity checks on the final tables
16SpostProcessingFORALLDATA-Alex.Rmd   figures, stats, and corncob, run in RStudio
```

## 1. build the metadata, build_metadata.R

makes the sample info table from the Eggleston Lab Sample Database spreadsheet. site, date, season, probe readings (water temp, pH, chlorophyll, phycocyanin, and so on), and bloom phase. 18S uses this same table. rerun it whenever new samples get added.

```
conda activate dada2
Rscript build_metadata.R
```

output -> `metadata_E400to672.csv`

*note, bloom phases (pre, bloom, post) come straight from Table 2 of Camilla Salwen's thesis, not recalculated from phycocyanin. MAB is always "Non". 2025 and 2026 are left blank on purpose, her method needs field observations we do not have for those years.

## 2. clean up each batch, dada2_batch.R

the big cleaning step. for one batch it cuts the primers off, trims the bad ends of the reads, throws out low quality reads, fixes sequencing errors, and joins each forward read to its reverse read. it also saves quality plots.

run it once per batch
```
sbatch run_dada2_batch.slurm run1 paired
sbatch run_dada2_batch.slurm summer24 paired
sbatch run_dada2_batch.slurm old508 paired
sbatch run_dada2_batch.slurm new589 paired
sbatch run_dada2_batch.slurm oldest paired
```

the batches
- run1, E415 to E482
- summer24, E490 to E507
- old508, E508 to E588
- new589, E589 onward
- oldest, E400 to E409, the winter 2022 to 2023 samples

"paired" uses both forward and reverse reads, "fwd" uses only forward reads (Camilla's original approach).

outputs, in `dada2_out_paired/` ->
- `seqtab_BATCH.rds`, the ASV table for that batch
- `track_BATCH.csv`, how many reads survived each step per sample
- `quality_BATCH.pdf` and `errors_BATCH.pdf`, the plots

*note, check `track_BATCH.csv` after every batch. if "merged" is way lower than "filtered", the reads are not overlapping and the trim lengths need changing.

*note, the oldest batch came from a different facility with shorter reads and no primers, so it gets its own trim settings. the normal settings throw out every read.

*note, do not change the cpu setting to `multithread=TRUE`, the job runs out of memory and dies.

*note, the script also has a batch called run2. it is a rerun of run1 and does not get merged, run1 is the one used.

## 3. merge and assign taxonomy, merge_batches.R

once every batch is done, this
1. stitches all the batch tables into one
2. removes chimeras, fake sequences made by accident during copying
3. names every ASV using the SILVA r138 (2019) reference, the same one the lab has used since Camilla
4. removes chloroplast and mitochondria ASVs, which the 16S primers pick up from algae

```
sbatch run_merge.slurm paired
```

outputs, in `dada2_out_paired/` ->
- `ASVs_counts_ALL.csv`, how many reads of each ASV in each sample
- `ASVs_taxonomy_ALL.csv`, what each ASV is
- `ASVs_ALL.fa`, the DNA sequence of each ASV
- `seqtab_nochim_ALL.rds` and `taxid_ALL.rds`, the same tables in R format

*note, do not point this at the 18S reference, it only has eukaryotes so every bacterium comes back unnamed.

## 4. sanity check, qc_16S.R

prints a bunch of checks without changing anything. whether every sample has metadata (any that do not get silently dropped later), read counts per sample, the most common phyla, and whether cyanobacteria are higher at MIS and STA than MAB in bloom months like they should be.

```
Rscript qc_16S.R paired
```

*note, the 2023 samples were sequenced about 4x shallower than the newer ones, keep that in mind before comparing across years.

## 5. figures, stats, and corncob, 16SpostProcessingFORALLDATA-Alex.Rmd

download the three csvs and the metadata csv from ada, then open this in RStudio. what it does is laid out in `../README.md` (the amplicons overview).
