#!/bin/bash
#SBATCH --job-name=xml_build\
#SBATCH --output=xml_build_%j.out\
#SBATCH --error=xml_build_%j.err
#SBATCH --mail-user=jklomparens@middlebury.edu
#SBATCH --mail-type=ALL
#SBATCH --mem=32GB
#SBATCH --partition=standard
#SBATCH --time=02:00:00

echo "Job ID: $\{SLURM_JOB_ID\}"
echo "Node: $\{SLURMD_NODENAME\}" 
echo "Starting: "`date +"%D %T"`

# this resulting .xml file provides design and format instructions for CGView

perl /path/to/cgview/scripts/cgview_xml_builder/cgview_xml_builder.pl \
    -sequence prokka_output/bin1/annotation.gbk \
    -label prokka_output/bin1/locus_to_label.txt \
    -size medium \ # graph size small/medium/large
    -gc_content T \ # display GC content? T/F
    -gc_skew T \ # display DC skew? T/F
    -title " " \ # fill in for figure title
    -details F \ # display details about figure
    -output prokka_output/bin1/prokka.xml

echo "Ending: "`date +"%D %T"`
