## merge_batches_18S.R
## Stitch the five per batch seqtabs into one table, take chimeras off the
## merged table, filter to the real amplicon length, then assign taxonomy.
## Run after all five batch jobs finish.

library(dada2)
library(DECIPHER)

ncores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset="1"))
args <- commandArgs(trailingOnly=TRUE)
mode <- if (length(args) > 0) args[1] else "paired"
if (!mode %in% c("fwd","paired")) stop("mode must be fwd or paired")
base <- "/home/achrostowski/amplicon_18S_all"
out_dir <- file.path(base, paste0("dada2_out_", mode))

batches <- c("concat23","egg23","summer24","old508","new589")
tabs <- lapply(batches, function(b) readRDS(file.path(out_dir, paste0("seqtab_", b, ".rds"))))
names(tabs) <- batches
for (b in batches) cat(b, ":", nrow(tabs[[b]]), "samples,", ncol(tabs[[b]]), "ASVs\n")

st <- mergeSequenceTables(tabs[["concat23"]], tabs[["egg23"]], tabs[["summer24"]],
                          tabs[["old508"]], tabs[["new589"]])
cat("merged:", nrow(st), "samples,", ncol(st), "ASVs\n")

st.nochim <- removeBimeraDenovo(st, method="consensus", multithread=ncores, verbose=TRUE)
cat("nochim:", nrow(st.nochim), "samples,", ncol(st.nochim), "ASVs\n")
cat("fraction of reads kept:", sum(st.nochim)/sum(st), "\n")

## 18S V4 length varies across eukaryotes. the previous run's seqtab_lenfilt
## ran 365 to 448bp, so anything shorter is a junk merge. 16S does not need
## this step because V4V5 is a fixed length, and 18S does not need the
## chloroplast/mito step because it targets eukaryotes.
print(table(nchar(getSequences(st.nochim))))
lens <- nchar(getSequences(st.nochim))
st.lenfilt <- st.nochim[, lens >= 365 & lens <= 448, drop=FALSE]
cat("lenfilt:", nrow(st.lenfilt), "samples,", ncol(st.lenfilt), "ASVs\n")
saveRDS(st.lenfilt, file.path(out_dir, "seqtab_lenfilt_ALL.rds"))

## the eukaryote subset training set built from SILVA 138.2 by BuildFile.R.
## the 16S set has no eukaryotes in it, do not point this at that one.
load("/home/achrostowski/Eggleston18SProcessingAlex/SILVA_SSU_r138.2_v2.RData")
dna <- DNAStringSet(getSequences(st.lenfilt))
ids <- IdTaxa(dna, trainingSet, strand="both", threshold=60, processors=ncores, verbose=TRUE)
saveRDS(ids, file.path(out_dir, "ids_ALL.rds"))

## SILVA eukaryote ranks. it uses kingdom where the prokaryote side uses phylum,
## and it has no species at all. variable depth means a lineage can skip levels,
## so class can end up more populated than phylum. that is the database.
## division does NOT exist here, asking for it returns an empty column.
ranks <- c("domain","kingdom","phylum","class","order","family","genus")
taxid <- t(sapply(ids, function(x) {
  m <- match(ranks, x$rank)
  taxa <- x$taxon[m]
  taxa[startsWith(taxa, "unclassified_")] <- NA
  taxa
}))
colnames(taxid) <- ranks
rownames(taxid) <- getSequences(st.lenfilt)
saveRDS(taxid, file.path(out_dir, "taxid_matrix_ranked.rds"))
print(apply(taxid, 2, function(col) sum(!is.na(col))))

asv_seqs <- colnames(st.lenfilt)
asv_ids <- paste0("ASV_", seq_along(asv_seqs))
writeLines(c(rbind(paste0(">", asv_ids), asv_seqs)), file.path(out_dir, "ASVs_18S_ALL.fa"))
counts <- t(st.lenfilt)
rownames(counts) <- asv_ids
write.csv(counts, file.path(out_dir, "ASVs_counts_18S_ALL.csv"))
tax_out <- taxid
rownames(tax_out) <- asv_ids
write.csv(tax_out, file.path(out_dir, "ASVs_taxonomy_18S_ALL.csv"))