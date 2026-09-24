# Amplicons, 16S and 18S

16S and 18S are "amplicon" sequencing. instead of sequencing all the DNA in a sample, the lab copies one gene and sequences just that. every bacterium has a 16S gene and every eukaryote has an 18S gene, and the small differences in that gene tell you who is who.

reads come back as `.fastq` files, one forward (R1) and one reverse (R2) per sample. DADA2 cleans them up and turns them into ASVs (amplicon sequence variants), the exact unique DNA sequences in the data. each ASV gets a name, and you end up with a table of how many reads of each ASV showed up in each sample. everything downstream is built off that table.

16S covers 251 samples (E400 to E672). 18S covers 213 samples (E417 to E672).

## The Order

detailed steps are in `16S/README.md` and `18S/README.md`. both go
1. build the metadata table (16S folder, used by both)
2. clean up each sequencing batch on its own
3. merge the batches and assign taxonomy
4. sanity check
5. figures and stats in R
6. corncob

samples came back in separate batches over three years, each with its own file names and sometimes different read lengths. so each batch gets processed on its own first, then they all get merged.

steps 1 to 4 run on ada, 5 and 6 run in RStudio on your laptop.

## 5. Figures and Stats, the Post Processing Rmds

download the output csvs from ada, then open `16S/16SpostProcessingFORALLDATA-Alex.Rmd` or `18S/18SPostProcessing.Rmd` in RStudio and point them at the csvs. they
1. load the counts, taxonomy, and metadata into phyloseq
2. keep taxa that make up more than 0.5% of the total
3. make stacked bar charts of who is there over time at each site, at phylum, class, order, and family level. if the legend gets too big it saves as its own image
4. make NMDS plots to see how similar samples are to each other, colored by site and season
5. test whether communities differ by site and by season
6. calculate Shannon diversity

results so far, for 18S season explains more of the differences between communities than site does.

*note, samples from the same site over time are not independent of each other, so treat those stats as rough.

## 6. Corncob

corncob checks each ASV one at a time to see if it is more or less common at MIS or STA than at MAB, so every result reads as "compared to the non bloom site". it follows Camilla's thesis method. the code is in the post processing rmds.

results so far, 16S found 322 ASVs that differ by site, 18S found 230. the top hits get plotted as two panel figures, MIS on one side and STA on the other.

*note, the bloom vs non bloom version only has about 5 samples per group, so a lot of it fails to fit. treat those results as weak.
