## qc_16S.R
## Sanity check the merged 16S tables before wiring them into phyloseq.
## Takes the mode as an argument. Reports to stdout, writes nothing.

library(dada2)

args <- commandArgs(trailingOnly=TRUE)
mode <- if (length(args) > 0) args[1] else "paired"
base <- "/home/achrostowski/amplicon_16S_all"
d <- file.path(base, paste0("dada2_out_", mode))

st <- readRDS(file.path(d, "seqtab_nochim_ALL.rds"))
tax <- readRDS(file.path(d, "taxid_ALL.rds"))
meta <- read.csv(file.path(base, "metadata_E400to672.csv"), row.names=1)
cat(mode, ":", nrow(st), "samples,", ncol(st), "ASVs\n\n")

## sample names are bare euro numbers, metadata rownames are the same.
## every sequenced sample MUST have metadata or phyloseq drops it silently.
s <- rownames(st)
m <- rownames(meta)
cat("samples with no metadata:", paste(setdiff(s, m), collapse=" "), "\n")
cat("metadata rows with no sample:", length(setdiff(m, s)), "\n\n")

## depth drives richness. 2023 was sequenced ~4x shallower than the new data
## so this spread is the thing to watch before any diversity comparison.
depth <- rowSums(st)
cat("read depth per sample\n")
print(summary(depth))
cat("\ndepth by year\n")
yr <- format(as.Date(meta[s, "Date"], format="%m/%d/%y"), "%Y")
print(tapply(depth, yr, function(x) round(c(n=length(x), median=median(x)))))

## dominant phyla. freshwater should be Proteobacteria, Actinobacteriota,
## Bacteroidota, Verrucomicrobiota, Cyanobacteria.
rel <- sweep(st, 1, rowSums(st), "/")
ph <- tax[, "phylum"]
ph_sum <- tapply(colMeans(rel), ph, sum)
cat("\ntop phyla by mean relative abundance\n")
print(round(sort(ph_sum, decreasing=TRUE)[1:12], 4))
cat("unassigned at phylum:", round(sum(colMeans(rel)[is.na(ph)]), 4), "\n")

## the real biological check. cyanos should be high at MIS and STA in the
## bloom months and low at MAB, which is the non bloom reference site.
cy <- !is.na(ph) & ph == "Cyanobacteria"
cat("\ncyanobacteria ASVs:", sum(cy), "\n")
cy_rel <- rowSums(rel[, cy, drop=FALSE])
cat("\ncyano relative abundance by site\n")
print(round(tapply(cy_rel, meta[s, "Location"], median), 4))
cat("\ncyano relative abundance by site and season\n")
print(round(tapply(cy_rel, list(meta[s,"Location"], meta[s,"Season"]), median), 4))
cat("\ncyano relative abundance by bloom status\n")
print(round(tapply(cy_rel, meta[s, "BloomStatus"], median), 4))

## if PC says bloom the cyanos should agree. a flat relationship here means
## either the bloom call or the sequencing is not saying what we think.
pc <- suppressWarnings(as.numeric(meta[s, "PC"]))
ok <- !is.na(pc) & !is.na(cy_rel)
cat("\ncyano vs phycocyanin, spearman:", round(cor(pc[ok], cy_rel[ok], method="spearman"), 3), "\n")