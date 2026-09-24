# Viromes

finds viruses in the metagenome assemblies, especially cyanophages, the viruses that infect cyanobacteria.

this runs on the site assemblies from `../metagenomics/` (`results/SITE/megahit/final.contigs.fa`), so do that first. runs on ada from a folder called `~/virome_out`. see the root readme for ada, conda, and SLURM basics.

## Files

```
run_genomad.slurm    finds viral sequences in an assembly
run_checkv.slurm     grades how complete those viral sequences are
```

## The Order
1. rename the contigs
2. find viral sequences with genomad
3. check their quality with checkv
4. compare them to known viruses with IMG/VR and BLAST
5. annotate their genes with DRAM-v

## Setting Up

genomad and checkv live in the `virome` conda environment and each need a database downloaded once.

*note, ada cannot download genomad's database directly. install genomad on your laptop, download it there, then copy it over
```
genomad download-database ~/Desktop/genomad_db_download/
scp -r ~/Desktop/genomad_db_download/genomad_db "ada:~/virome_dbs/genomad_db"
```

*note, checkv's database downloads fine on ada, but the folder name does not match what the script looks for, so make a shortcut
```
conda activate virome
checkv download_database ~/virome_dbs/
ln -s ~/virome_dbs/checkv-db-v1.5 ~/virome_dbs/checkv_db
```

## 1. Rename the Contigs

every assembly names its contigs `k141_1`, `k141_2`, and so on, so different sites would end up with the same names. put the site name in front first
```
cd ~/virome_out
mkdir -p renamed_contigs
sed 's/^>/>MIS_full_/' ~/Eggleston_Metagenomes/results/MIS/megahit/final.contigs.fa > renamed_contigs/MIS_full.contigs.fa
grep -c "^>" renamed_contigs/MIS_full.contigs.fa
```

that last line counts the contigs, it should match the original assembly. do the same for STA and MAB.

## 2. Find Viral Sequences, run_genomad.slurm

genomad goes through every contig and decides if it looks like a virus, a plasmid, or regular DNA, and gives the viral ones a rough taxonomy.
```
sbatch run_genomad.slurm renamed_contigs/MIS_full.contigs.fa MIS_full
```

takes about 15 to 20 minutes per site.

outputs, in `genomad/SITE/SITE.contigs_summary/` ->
- `SITE.contigs_virus.fna`, the viral sequences
- `SITE.contigs_virus_summary.tsv`, one row per viral sequence with its score and taxonomy

## 3. Check Quality, run_checkv.slurm

genomad says what looks viral, checkv says how complete each one actually is. basically checkm but for viruses. it sorts each one into complete, high, medium, low, or not determined.
```
sbatch run_checkv.slurm MIS_full
```

use the same name you gave genomad.

output -> `checkv/SITE/quality_summary.tsv`

results so far, genomad found 11,200 viral sequences at MIS, 3,832 at STA, and 3,931 at MAB, but only about 1% come out medium quality or better at every site. MIS has the most good ones (160, including 29 complete).

cyanophage family (Kyanoviridae) sequences show up at all three sites, but mostly as short pieces, usually under 10% of a full genome. so they are definitely there, there just is not enough of any one to rebuild the whole thing.

## 4. Compare to Known Viruses, IMG/VR and BLAST

IMG/VR is a huge Department of Energy database of viruses other people have already found. comparing our pieces against it tells us what they most likely are.

### Downloading

1. make a free JGI account and go to IMG/VR on the JGI data portal
2. from the `IMG_VR_2022-12-19_7` release, get the full files, not the high confidence ones, since that set is too small to match our short pieces against
    - `IMGVR_all_Sequence_information.tsv`, taxonomy for every virus
    - `IMGVR_all_Host_information.tsv`, which organism each virus infects, when known
    - `IMGVR_all_nucleotides.fna.gz`, the actual sequences, 45 GB
3. in the cart pick "Command line download", which gives you a curl command. add `nohup` to the front and `> download.log 2>&1 &` to the end so it runs in the background
4. unzip what comes back, then `gunzip -k` the `.fna.gz`

*note, the curl command expires after about 12 hours. if the download comes back tiny and says "Authentication credentials were not provided", log back into the portal and get a fresh one.

*note, the unzipped sequence file is around 160 GB. pull out what you need then delete it, or you will run out of space on ada.

### Pulling Out the Reference Viruses

grab the IDs of every virus IMG/VR calls Kyanoviridae, then pull just those sequences out of the big file
```
grep -i "Kyanoviridae" seq_info_full/Cus_VR/IMG_VR_2022-12-19_7/IMGVR_all_Sequence_information.tsv | awk -F'\t' '{print $1}' > kyano_taxonomy_ids.txt

python3 -c "
ids = set(open('kyano_taxonomy_ids.txt').read().split())
with open('nucleotides_full/Cus_VR/IMG_VR_2022-12-19_7/IMGVR_all_nucleotides.fna') as f, open('kyano_taxonomy_full.fna', 'w') as out:
    write = False
    for line in f:
        if line.startswith('>'):
            write = line[1:].split('|')[0].strip() in ids
        if write:
            out.write(line)
"
```

that gives 73,204 reference sequences.

### BLAST

pull your own Kyanoviridae pieces out of each site the same way (grep the genomad summary, then pull from `SITE.contigs_virus.fna`), then build a BLAST database from the references and search against it
```
conda activate blast
makeblastdb -in kyano_taxonomy_full.fna -dbtype nucl -out kyano_taxonomy_db
blastn -query kyano_all_MIS.fna -db kyano_taxonomy_db -outfmt 6 -evalue 1e-6 -out blast_taxonomy_MIS.tsv
```

*note, BLAST does not add column names to its output, add them before sharing the file.

results so far, about half our Kyanoviridae pieces at each site match a known genome, with long matches at 84 to 98% identity. the best match came from a freshwater river.

*note, searching only against viruses with a known Microcystis or Dolichospermum host found nothing, because most IMG/VR Kyanoviridae never got a host assigned. so right now we can say ours look like known cyanophages, not which cyanobacterium they infect.

## 5. Annotate Viral Genes, DRAM-v

DRAM-v labels the genes on the viral sequences. the interesting ones are AMGs, genes a phage picks up from its host.

build the `dram` environment with mamba and python 3.8, then set up the databases
```
conda activate mamba_env
mamba create -n dram -c bioconda -c conda-forge python=3.8 dram -y
conda activate dram
DRAM-setup.py prepare_databases --output_dir ~/dram_data \
  --kofam_hmm_loc ~/dram_data/database_files_saved/kofam_profiles.tar.gz \
  --kofam_ko_list_loc ~/dram_data/database_files_saved/kofam_ko_list.tsv.gz \
  --uniref_loc ~/dram_data/database_files_saved/uniref90.fasta.gz \
  --threads 16
```

this uses the free databases, not paid KEGG.

*note, DRAM's own UniRef90 download link is dead. download it yourself (about 30 GB)
```
curl -C - -o uniref90.fasta.gz "https://ftp.ebi.ac.uk/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz"
```

*note, setup crashes if a `database_files` folder already exists. rename the old one and point the `--..._loc` options at the files inside it, like above.

*note, the finished databases take up well over 100 GB, check your space first.

*note, DRAM-v was built around VirSorter output, check its docs for how to feed it genomad output before annotating.
