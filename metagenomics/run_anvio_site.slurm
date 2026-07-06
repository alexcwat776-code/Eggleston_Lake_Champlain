#!/bin/bash
#SBATCH --job-name=anvio_site
#SBATCH --partition=standard
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=10:00:00
#SBATCH --output=anvio_%x_%j.log
# ^ set the queue/memory/time to whatever your cluster uses
set -euo pipefail
SITE="${1:?ERROR: provide a site, e.g. sbatch run_anvio_site.slurm STA}"  # pass the site as an argument
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh  # point this to wherever conda is installed on your machine
conda activate anvio-9
cd ~/Eggleston_Metagenomes  # cd into wherever you keep the project
# sample lists per site, edit these to match your own samples
case "$SITE" in
  MIS) SAMPLES="E508 E514 E523 E532 E538 E544 E553 E562 E574 E577 E586" ;;
  STA) SAMPLES="E509 E515 E524 E533 E539 E545 E554 E563 E575 E578 E587" ;;
  MAB) SAMPLES="E516 E525 E534 E540 E546 E555 E564 E576 E579 E588" ;;
  *)   exit 1 ;;
esac
ASSEMBLY="results/${SITE}/megahit/final.contigs.fa"
BAMDIR="results/${SITE}/mapped"
BINDIR="results/${SITE}/bins"
OUTDIR="anvio_${SITE}"
CONTIGS="${OUTDIR}/CONTIGS.db"
PROFDIR="${OUTDIR}/profiles"
MERGED="${OUTDIR}/MERGED-PROFILE"
COLLECTION="${OUTDIR}/collection_metabat2.txt"
mkdir -p "$OUTDIR" "$PROFDIR"
# strip the descriptions off the contig headers so anvio takes them, keeps the k141 ids so the bams still match
sed '/^>/ s/ .*//' "$ASSEMBLY" > "${OUTDIR}/contigs_fixed.fa"
anvi-gen-contigs-database -f "${OUTDIR}/contigs_fixed.fa" -o "$CONTIGS" -n "${SITE}_metagenome" -T 16
anvi-run-hmms -c "$CONTIGS" -T 16
for S in $SAMPLES; do
    anvi-profile -i "${BAMDIR}/${S}.bam" -c "$CONTIGS" -o "${PROFDIR}/${S}" -S "S_${S}" -T 16
done
anvi-merge "${PROFDIR}"/*/PROFILE.db -c "$CONTIGS" -o "$MERGED" -S "${SITE}_merged"
# build the collection file mapping each contig to its bin
: > "$COLLECTION"
for f in "${BINDIR}"/*.fa; do
    bin=$(basename "$f" .fa | sed 's/[.\-]/_/g')
    grep "^>" "$f" | awk -v b="$bin" '{sub(/^>/,""); print $1"\t"b}' >> "$COLLECTION"
done
# --contigs-mode maps contigs to splits, needed or the import finds nothing
anvi-import-collection "$COLLECTION" -c "$CONTIGS" -p "${MERGED}/PROFILE.db" -C metabat2 --contigs-mode
