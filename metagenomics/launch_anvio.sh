#!/bin/bash
# open the anvio interface for one site, run this directly (not sbatch): bash launch_anvio.sh STA
set -euo pipefail
SITE="${1:?ERROR: give a site, e.g. bash launch_anvio.sh STA}"
# each site gets its own port so you can open more than one at once
case "$SITE" in
  MIS) PORT=8080 ;;
  STA) PORT=8081 ;;
  MAB) PORT=8082 ;;
  *)   exit 1 ;;
esac
cd ~/Eggleston_Metagenomes  # cd into wherever you keep the project
CONTIGS="anvio_${SITE}/CONTIGS.db"
PROFILE="anvio_${SITE}/MERGED-PROFILE/PROFILE.db"
if [[ ! -f "$CONTIGS" || ! -f "$PROFILE" ]]; then
  exit 1
fi
source /home/mlinderman/modules/miniconda3/latest/etc/profile.d/conda.sh  # point this to wherever conda is installed on your machine
conda activate anvio-9
# once running: forward the port in VS Code (PORTS tab), open http://localhost:PORT in chrome, click DRAW
anvi-interactive -c "$CONTIGS" -p "$PROFILE" -C metabat2 --server-only -P "$PORT"
