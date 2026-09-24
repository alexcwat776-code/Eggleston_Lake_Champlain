#teaching the software what each eukaryotic group's DNA looks like, 
#so taxonomy can be assigned to your ASVs afterward
#Next is metagenome workflow and find 3 papers. 
library(DECIPHER)
fasta_file <- "/home/achrostowski/Eggleston18SProcessingAlex/SILVA_138.2_SSURef_NR99_tax_silva.fasta.gz"
seqs <- DNAStringSet(readRNAStringSet(fasta_file)) 
seqs <- RemoveGaps(seqs)
headers <- names(seqs)
accession <- sub("\\s.*$", "", headers)
lineage <- sub("^\\S+\\s+", "", headers)
keep <- grepl("^Eukaryota", lineage)
seqs <- seqs[keep]
accession <- accession[keep]
lineage <- lineage[keep]
taxonomy <- paste0("Root;", lineage)
names(seqs) <- accession
set.seed(123)
trainingSet <- LearnTaxa(train = seqs, taxonomy = taxonomy)
saveRDS(trainingSet, "/home/achrostowski/Eggleston18SProcessingAlex/SILVA_138.2_SSU_EUK_trainingSet_v2.rds")
print(trainingSet)
