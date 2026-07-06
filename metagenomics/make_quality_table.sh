#!/bin/bash
# tally MAG quality from a checkm table: bash make_quality_table.sh MIS
set -euo pipefail
SITE="${1:?give a site, e.g. bash make_quality_table.sh MIS}"
IN=~/Eggleston_Metagenomes/results/${SITE}/checkm_${SITE}_quality.tsv  # checkm output for the site
OUT=~/Eggleston_Metagenomes/results/${SITE}/checkm_${SITE}_quality_SORTED.txt
# col 12 = completeness, col 13 = contamination (checkm's column order, verify if your version differs)
awk -F'\t' 'NR==1{print $0"\tQuality"; next} {c=$12+0; x=$13+0; q="LOW"; if(c>=50 && x<10) q="MEDIUM"; if(c>=90 && x<5) q="HIGH"; print $0"\t"q}' "$IN" > /tmp/_withq.tsv
{ head -1 /tmp/_withq.tsv; tail -n +2 /tmp/_withq.tsv | sort -t$'\t' -k12 -gr; } | column -t -s$'\t' > "$OUT"
rm -f /tmp/_withq.tsv
