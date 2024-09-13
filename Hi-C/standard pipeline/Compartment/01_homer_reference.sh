#Generation of homer for pig annotation files using reference genomes and annotation files
ref= #reference genome
gtf= #gtf of reference genome
singularity exec miniconda_homer_R.sif loadGenome.pl -name ref -org null -fasta $ref -gtf $gtf