# Archive

the first test runs from before the snakemake pipeline, done by hand one step at a time. kept so you can see how each step works on its own. you do not need to run any of these, `../run_SITE.slurm` does all of it now.

the tests went small to big, one sample, then three pooled, then the full sites.

## Files

```
megahit_trial_E508.slurm    assembled one sample (E508) by itself
map_E508.slurm              mapped E508's reads back to its own assembly
megahit_trial_MIS3.slurm    assembled three MIS samples pooled (E508, E514, E523), the "MIS3" test
map_E508_to_MIS3.slurm      mapped E508's reads onto the MIS3 assembly, also builds the index
map_MIS3_rest.slurm         mapped E514 and E523 onto the MIS3 assembly
bin_MIS3.slurm              made the coverage table and ran metabat2 on MIS3
checkm_MIS3.slurm           graded the MIS3 bins with checkm
prokka_bin52.slurm          annotated genes on bin 52 from MIS3, a high quality bin
```

## Order They Ran In
1. `megahit_trial_E508.slurm` -> `megahit_E508/final.contigs.fa`
2. `map_E508.slurm` -> `mapped/E508.bam`
3. `megahit_trial_MIS3.slurm` -> `megahit_MIS3/final.contigs.fa`
4. `map_E508_to_MIS3.slurm`, then `map_MIS3_rest.slurm` -> `mapped_MIS3/E508.bam`, `E514.bam`, `E523.bam`
5. `bin_MIS3.slurm` -> `bins_MIS3/`
6. `checkm_MIS3.slurm` -> `checkm_MIS3_quality.tsv`
7. `prokka_bin52.slurm` -> `prokka_MIS3/bin52/`

*note, `prokka_bin52.slurm` is still the only prokka script there is. copy it and change the bin name to annotate a different bin.

*note, "MIS3" means three MIS samples pooled together, not the full MIS run, which pools all 11.
