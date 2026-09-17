## merge_batches.R
## Stitch the four per batch seqtabs into one table, take chimeras off the
## merged table, then assign taxonomy. Run after all four batch jobs finish.

library(dada2)
library(DECIPHER)

ncores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset="1"))
args <- commandArgs(trailingOnly=TRUE)
mode <- if (length(args) > 0) args[1] else "paired"
if (!mode %in% c("fwd","paired")) stop("mode must be fwd or paired")
out_dir <- paste0("/home/achrostowski/amplicon_16S_all/dada2_out_", mode)


batches <- c("run1","summer24","old508","new589","oldest")
tabs <- lapply(batches, function(b) readRDS(file.path(out_dir, paste0("seqtab_", b, ".rds"))))
names(tabs) <- batches
for (b in batches) cat(b, ":", nrow(tabs[[b]]), "samples,", ncol(tabs[[b]]), "ASVs\n")

## ASVs match across batches by exact sequence. that is why these merge at all
## and why the ASV_1 labels in the old csvs could not be merged into.
st <- mergeSequenceTables(tables = tabs)
cat("merged:", nrow(st), "samples,", ncol(st), "ASVs\n")

## chimeras come off here, once, on everything. more samples means better
## detection than doing it per batch.
st.nochim <- removeBimeraDenovo(st, method="consensus", multithread=ncores, verbose=TRUE)
cat("nochim:", nrow(st.nochim), "samples,", ncol(st.nochim), "ASVs\n")
cat("fraction of reads kept:", sum(st.nochim)/sum(st), "\n")
saveRDS(st.nochim, file.path(out_dir, "seqtab_nochim_ALL.rds"))

## SILVA r138 2019 is the 16S set the lab has used since Camilla. the eukaryote
## set built for 18S has no bacteria in it, so do not point this at that one.
load("/home/achrostowski/amplicon_16S_all/SILVA_SSU_r138_2019.RData")
dna <- DNAStringSet(getSequences(st.nochim))
ids <- IdTaxa(dna, trainingSet, strand="top", processors=ncores, verbose=TRUE)
saveRDS(ids, file.path(out_dir, "ids_ALL.rds"))

## these are the prokaryote ranks. the 18S eukaryote side uses kingdom instead
## of phylum and has no species, so do not reuse this vector there.
ranks <- c("domain","phylum","class","order","family","genus","species")
taxid <- t(sapply(ids, function(x) {
  m <- match(ranks, x$rank)
  taxa <- x$taxon[m]
  taxa[startsWith(taxa, "unclassified_")] <- NA
  taxa
}))
colnames(taxid) <- ranks
rownames(taxid) <- getSequences(st.nochim)
print(apply(taxid, 2, function(col) sum(!is.na(col))))
## SILVA files chloroplast as an order and mitochondria as a family, both under
## Bacteria. 16S primers amplify both and lake water is full of algae, so they
## swamp the bar plots. Camilla's tables were _no_chloromito for this reason.
drop <- (!is.na(taxid[,"order"]) & taxid[,"order"] == "Chloroplast") |
        (!is.na(taxid[,"family"]) & taxid[,"family"] == "Mitochondria")
cat("dropping", sum(drop), "chloroplast/mito ASVs of", nrow(taxid), "\n")
st.nochim <- st.nochim[, !drop, drop=FALSE]
taxid <- taxid[!drop, , drop=FALSE]
cat("after chloromito:", nrow(st.nochim), "samples,", ncol(st.nochim), "ASVs\n")
saveRDS(taxid, file.path(out_dir, "taxid_ALL.rds"))

## write the sequences out. the old csvs relabelled ASVs as ASV_1, ASV_2 and
## dropped the sequences, which is why nothing could be merged into them.
asv_seqs <- colnames(st.nochim)
asv_ids <- paste0("ASV_", seq_along(asv_seqs))
writeLines(c(rbind(paste0(">", asv_ids), asv_seqs)), file.path(out_dir, "ASVs_ALL.fa"))
counts <- t(st.nochim)
rownames(counts) <- asv_ids
write.csv(counts, file.path(out_dir, "ASVs_counts_ALL.csv"))
tax_out <- taxid
rownames(tax_out) <- asv_ids
write.csv(tax_out, file.path(out_dir, "ASVs_taxonomy_ALL.csv"))