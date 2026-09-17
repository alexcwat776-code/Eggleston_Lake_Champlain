## dada2_batch.R
## Run DADA2 on one 16S batch. Takes the batch name and the mode as arguments.
## Each batch is its own sequencing run so it gets its own error model.
## merge_batches.R stitches the per batch seqtabs together afterwards.

library(dada2)

## multithread=TRUE calls detectCores() which sees the whole node, not the
## slurm allocation, and forks enough workers to OOM the job. MUST pass the
## explicit count from the allocation instead.
ncores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset="1"))

args <- commandArgs(trailingOnly=TRUE)
batch <- args[1]

## second arg picks the method. fwd is Camilla's forward only approach, paired
## merges the reverse reads in. outputs go to separate directories so both can
## exist side by side.
mode <- if (length(args) > 1) args[2] else "paired"
if (!mode %in% c("fwd","paired")) stop("mode must be fwd or paired")

## Six batches now, six naming conventions. The euro number is the only thing
## that ties them together so pull it out per batch.
cfg <- list(
  run1 = list(dir="/home/achrostowski/amplicon_16S_all/run1_E415-482", pat="^Egg([0-9]+)_.*$"),
  run2 = list(dir="/home/achrostowski/amplicon_16S_all/run2_E415-482", pat="^Egg([0-9]+)_.*$"),
  summer24 = list(dir="/home/achrostowski/amplicon_16S_all/summer24_E490-507", pat="^B-([0-9]+)_.*$"),
  old508 = list(dir="/home/achrostowski/amplicon_16S_all/E508-588_raw/EgglestonV4V5", pat="^E([0-9]+)_.*$"),
  new589 = list(dir="/home/achrostowski/amplicon_2026/EgglestonV4V5", pat="^A_([0-9]+)_.*$"),
  oldest = list(dir="/home/achrostowski/amplicon_16S_all/oldest_A400-409", pat="^A\\.([0-9]+)\\.1_1\\.fastq\\.gz$", recursive=TRUE)
)
if (!batch %in% names(cfg)) stop("batch must be one of: run1 run2 summer24 old508 new589 oldest")
path <- cfg[[batch]]$dir
pat <- cfg[[batch]]$pat

out_dir <- paste0("/home/achrostowski/amplicon_16S_all/dada2_out_", mode)
filt_dir <- file.path(out_dir, paste0("filtered_", batch))
dir.create(filt_dir, recursive=TRUE, showWarnings=FALSE)

## run1 is uncompressed, the rest are gz. Match both.
## oldest lives one sample per subfolder so it needs recursive=TRUE, and it
## uses _1/_2 not _R1/_R2, alongside .raw_1/.raw_2 and .extendedFrags which
## we are not using here.
if (isTRUE(cfg[[batch]]$recursive)) {
  fnFs <- sort(list.files(path, pattern=pat, full.names=TRUE, recursive=TRUE))
  fnRs <- sub("_1\\.fastq\\.gz$", "_2.fastq.gz", fnFs)
} else {
  fnFs <- sort(list.files(path, pattern="_R1_001\\.fastq(\\.gz)?$", full.names=TRUE))
  fnRs <- sort(list.files(path, pattern="_R2_001\\.fastq(\\.gz)?$", full.names=TRUE))
}
stopifnot(length(fnFs) == length(fnRs), length(fnFs) > 0)
stopifnot(all(file.exists(fnRs)))

## sample names are bare euro numbers so the batches can merge later.
## sub only replaces what it matches, so the pattern MUST end in .*$ or the
## rest of the filename comes along and the stopifnot fires.
sample.names <- sub(pat, "\\1", basename(fnFs))
stopifnot(!any(is.na(suppressWarnings(as.integer(sample.names)))))
cat(batch, mode, ":", length(sample.names), "samples,", sample.names[1], "to", sample.names[length(sample.names)], "\n")

## look at these before trusting truncLen
pdf(file.path(out_dir, paste0("quality_", batch, ".pdf")), width=10, height=6)
print(plotQualityProfile(fnFs[1:min(4, length(fnFs))]))
print(plotQualityProfile(fnRs[1:min(4, length(fnRs))]))
dev.off()

filtFs <- file.path(filt_dir, paste0(sample.names, "_F_filt.fastq.gz"))
filtRs <- file.path(filt_dir, paste0(sample.names, "_R_filt.fastq.gz"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

## trimLeft strips 515F and 926R, which are still on the reads.
## MUST keep this or the primers get denoised as biological sequence.
## truncLen leaves ~109bp overlap on a 411bp V4V5 amplicon. Camilla's own
## truncLen is not recoverable from her tracking file so these are ours.
## oldest is a different run entirely, 2022-23, different facility delivery.
## reads are only 223bp not 300bp, and primers are already stripped, so it
## needs its own trimLeft and truncLen. checked with plotQualityProfile.
if (batch == "oldest") {
  trimLeft_vals <- c(0,0)
  truncLen_vals <- c(200,180)
} else {
  trimLeft_vals <- c(19,20)
  truncLen_vals <- c(280,240)
}

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs,
                     trimLeft=trimLeft_vals, truncLen=truncLen_vals,
                     maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
                     compress=TRUE, multithread=ncores)

## drop samples that lost every read, otherwise learnErrors chokes
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
  ## Camilla's approach. the reverse reads get denoised then thrown away.
  seqtab <- makeSequenceTable(dadaFs)
  merged_n <- rep(NA, length(dadaFs))
} else {
  mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, verbose=TRUE)
  seqtab <- makeSequenceTable(mergers)
  merged_n <- sapply(mergers, getN)
}

## chimeras come off the merged table later, not here
saveRDS(seqtab, file.path(out_dir, paste0("seqtab_", batch, ".rds")))

## merged vs filtered is the test of truncLen in paired mode. if merged falls
## off a cliff the reads are not overlapping and truncLen needs raising.
track <- cbind(out[keep, , drop=FALSE],
               sapply(dadaFs, getN),
               sapply(dadaRs, getN),
               merged_n)
colnames(track) <- c("input","filtered","denoisedF","denoisedR","merged")
write.csv(track, file.path(out_dir, paste0("track_", batch, ".csv")))
print(track)

## paired should band tight around 370-410bp for V4V5. fwd is a single read so
## it sits at whatever truncLen minus trimLeft left behind.
print(table(nchar(getSequences(seqtab))))