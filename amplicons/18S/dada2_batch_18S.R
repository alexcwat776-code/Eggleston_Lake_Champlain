## dada2_batch_18S.R
## Run DADA2 on one 18S batch. Takes the batch name and the mode as arguments.
## Each batch is its own sequencing run so it gets its own error model.
## merge_batches_18S.R stitches the per batch seqtabs together afterwards.

library(dada2)

## multithread=TRUE calls detectCores() which sees the whole node, not the
## slurm allocation, and forks enough workers to OOM the job. MUST pass the
## explicit count from the allocation instead.
ncores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset="1"))

args <- commandArgs(trailingOnly=TRUE)
batch <- args[1]
mode <- if (length(args) > 1) args[2] else "paired"
if (!mode %in% c("fwd","paired")) stop("mode must be fwd or paired")

## Six batches now, six naming conventions. concat23 and egg23 share a
## directory, they are told apart by the file pattern. concat23 is 23 samples
## pooled from two sequencing runs, egg23 is 10 samples run once. oldest sits
## one sample per subfolder and uses a different suffix convention entirely.
base <- "/home/achrostowski/amplicon_18S_all"
cfg <- list(
  concat23 = list(dir=file.path(base,"concat_2023"), fpat="^[0-9]+_R1\\.fastq$", spat="^([0-9]+)_R1\\.fastq$"),
  egg23 = list(dir=file.path(base,"concat_2023"), fpat="^E-Egg[0-9]+_.*_R1_001\\.fastq$", spat="^E-Egg([0-9]+)_.*$"),
  summer24 = list(dir=file.path(base,"summer24_E490-507"), fpat="^E-[0-9]+_.*_R1_001\\.fastq\\.gz$", spat="^E-([0-9]+)_.*$"),
  old508 = list(dir=file.path(base,"E508-588_raw/Eggleston18SV4"), fpat="_R1_001\\.fastq\\.gz$", spat="^E_E([0-9]+)_.*$"),
  new589 = list(dir="/home/achrostowski/amplicon_2026/Eggleston18SV4", fpat="_R1_001\\.fastq\\.gz$", spat="^E-A_([0-9]+)_.*$"),
  oldest = list(dir=file.path(base,"oldest_A400-409"), fpat="\\.2_1\\.fastq\\.gz$", spat="^A\\.([0-9]+)\\.2_1\\.fastq\\.gz$", recursive=TRUE)
)
if (!batch %in% names(cfg)) stop("batch must be one of: concat23 egg23 summer24 old508 new589 oldest")
path <- cfg[[batch]]$dir

out_dir <- paste0(base, "/dada2_out_", mode)
filt_dir <- file.path(out_dir, paste0("filtered_", batch))
dir.create(filt_dir, recursive=TRUE, showWarnings=FALSE)

## derive R2 from R1 rather than listing it. the batches use different suffix
## conventions and sort order cannot be trusted to line them up. oldest sits
## one sample per subfolder and uses _1/_2, everything else uses _R1/_R2.
is_recursive <- isTRUE(cfg[[batch]]$recursive)
fnFs <- sort(list.files(path, pattern=cfg[[batch]]$fpat, full.names=TRUE, recursive=is_recursive))
fnRs <- if (batch == "oldest") sub("\\.2_1\\.fastq\\.gz$", ".2_2.fastq.gz", fnFs) else sub("_R1", "_R2", fnFs)
stopifnot(length(fnFs) > 0)

## E461 has no R2 anywhere in the drive. drop unpaired rather than let
## filterAndTrim fail on a missing file.
paired <- file.exists(fnRs)
if (any(!paired)) cat("dropping", sum(!paired), "unpaired:", basename(fnFs[!paired]), "\n")
fnFs <- fnFs[paired]
fnRs <- fnRs[paired]

sample.names <- sub(cfg[[batch]]$spat, "\\1", basename(fnFs))
stopifnot(!any(is.na(suppressWarnings(as.integer(sample.names)))))
cat(batch, mode, ":", length(sample.names), "samples,", sample.names[1], "to", sample.names[length(sample.names)], "\n")

pdf(file.path(out_dir, paste0("quality_", batch, ".pdf")), width=10, height=6)
print(plotQualityProfile(fnFs[1:min(4, length(fnFs))]))
print(plotQualityProfile(fnRs[1:min(4, length(fnRs))]))
dev.off()

filtFs <- file.path(filt_dir, paste0(sample.names, "_F_filt.fastq.gz"))
filtRs <- file.path(filt_dir, paste0(sample.names, "_R_filt.fastq.gz"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

## trimLeft strips E572F and E1009R, the 18S V4 primers. these are NOT the same
## as the 16S ones, do not copy that trimLeft over.
## 18S V4 length varies across eukaryotes, the existing seqtab runs 365 to 448bp.
## truncLen MUST leave room for the 448bp tail or the long eukaryotes silently
## fail to merge. 290+250 gives 502bp of read for a 448bp ASV.
## oldest already has primers stripped and reads are only 223bp, a different
## facility delivery entirely. quality holds Q33+ the whole read so no
## truncation needed, maxEE alone does the filtering.
if (batch == "oldest") {
  trimLeft_vals <- c(0,0)
  truncLen_vals <- c(0,0)
} else {
  trimLeft_vals <- c(18,20)
  truncLen_vals <- c(290,250)
}

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs,
                     trimLeft=trimLeft_vals, truncLen=truncLen_vals,
                     maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
                     compress=TRUE, multithread=ncores)

keep <- file.exists(filtFs) & file.exists(filtRs)
filtFs <- filtFs[keep]
filtRs <- filtRs[keep]

errF <- learnErrors(filtFs, multithread=ncores)
errR <- learnErrors(filtRs, multithread=ncores)
pdf(file.path(out_dir, paste0("errors_", batch, ".pdf")), width=8, height=8)
print(plotErrors(errF, nominalQ=TRUE))
print(plotErrors(errR, nominalQ=TRUE))
dev.off()

getN <- function(x) sum(getUniques(x))
dadaFs <- dada(filtFs, err=errF, multithread=ncores)
dadaRs <- dada(filtRs, err=errR, multithread=ncores)

if (mode == "fwd") {
  seqtab <- makeSequenceTable(dadaFs)
  merged_n <- rep(NA, length(dadaFs))
} else {
  mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose=TRUE)
  seqtab <- makeSequenceTable(mergers)
  merged_n <- sapply(mergers, getN)
}
saveRDS(seqtab, file.path(out_dir, paste0("seqtab_", batch, ".rds")))

track <- cbind(out[keep, , drop=FALSE],
               sapply(dadaFs, getN),
               sapply(dadaRs, getN),
               merged_n)
colnames(track) <- c("input","filtered","denoisedF","denoisedR","merged")
write.csv(track, file.path(out_dir, paste0("track_", batch, ".csv")))
print(track)

## should run 365 to 448bp. a tail below 365 is junk merges, the length filter
## in the merge step takes those off.
print(table(nchar(getSequences(seqtab))))
