# Scripts

This is the folder that contains the scripts for running the workflows.

## 1. run_trim_galore.sh

Runs the program [Trim Galore!](https://github.com/FelixKrueger/TrimGalore)

- `-i INPUT_DIR` Path to the input directory. View the expected structure below
- `-o OUTPUT_DIR` Path to the output directory
- `-p true|false`  Whether reads are paired-end (default: true)
- `-q QUALITY`     Phred quality score. Must be an integer between 0 and 100
- `-l LENGTH`      Discards reads shorter than the integer value

```
parent_data_folder/  
├── sample_01/  
│   ├── sample_01_R1.fastq.gz  
│   └── sample_01_R2.fastq.gz  
├── sample_02/  
│   ├── sample_02_R1.fastq.gz  
│   └── sample_02_R2.fastq.gz  
├── sample_03/  
│   ├── sample_03_R1.fastq.gz  
│   └── sample_03_R2.fastq.gz  
└── ...
```

## 2. run_megahit.sh

Runs [MEGAHIT](https://github.com/voutcn/megahit)
- `-i INPUT_DIR` Path to the input directory. View the expected structure below
- `-o OUTPUT_DIR` Path to the output directory
- `-b BATCH_SIZE` Number of samples to combine
- `-t THREADS` Number of CPU threads
- `--groups`   Optional: define your own folders to combine, like: "strain1,strain2;strain3,strain4", will override BATCH_SIZE parameter

```
parent_data_folder/  
├── sample_01/  
│   ├── *_R2_val_1.fq
│   └── *_R2_val_2.fq
├── sample_02/  
│   ├── *_R2_val_1.fq
│   └── *_R2_val_2.fq
└── ...
```

## 3. run_kraken2.sh
Runs the program [Kraken 2](https://github.com/DerrickWood/kraken2) and later combines the reports with KrakenTools [combine_kreports.py](https://github.com/jenniferlu717/KrakenTools/blob/master/combine_kreports.py)
- `-i INPUT_DIR` Path to the input directory. Input structure is below
- `-o OUTPUT_DIR` Path to the output directory
- `-d KRAKEN2_DB` Path to the Kraken2 database
- `-c CONFIDENCE` Confidence threshold (between 0 and 1)
- `-t THREADS` Number of CPU threads to use
- `-p PAIRED` Set 'true' for paired-end read analysis (Trim Galore! outputs), 'false' for assembled contigs (MEGAHIT outputs)

```
parent_data_folder/  
├── sample_01/  
│   └── final.contigs.fa
├── sample_02/  
│   └── final.contigs.fa 
├── sample_03/  
│   └── final.contigs.fa 
└── ...
```

## 4. run_bracken.sh
Runs [Bracken](https://github.com/jenniferlu717/Bracken) on Kraken reports.

- `-i INPUT_DIR` Path to the input directory. All reports should be contained in a single directory
- `-o OUTPUT_DIR` Path to the output directory
- `-d BRACKEN_DB` Path to the Bracken database
- `-r READ_LEN` Read length for Bracken (default: 100)
- `-l LEVEL` Taxonomic level (default: S)
- `-t THRESHOLD` Minimum abundance threshold for Bracken (default: 10)

## 5. filter_bracken_out.sh
Uses [filter_bracken.out.py](https://github.com/jenniferlu717/KrakenTools/blob/master/filter_bracken.out.py) from KrakenTools to filter taxonomies. Note that taxids in include and exclude lists shouldn't overlap.

- `-i INPUT_DIR` Path to the input directory. All reports should be contained in a single directory
- `-o OUTPUT_DIR` Path to the output directory
- `--include TAXID1 TAXID2` Space-separated taxonomy IDs to include
- `--exclude TAXID3 TAXID4` Space-separated taxonomy IDs to exclude

## 6. calculate_diversity.sh
Calculates alpha and beta diversity from Bracken reports using KrakenTools [DiversityTools](https://github.com/jenniferlu717/KrakenTools/tree/master/DiversityTools)

- `-i INPUT_DIR` Path to the input directory. All reports should be contained in a single directory
- `-o OUTPUT_DIR` Path to the output directory
- `-d DIVERSITY_TYPE` The diversity type for calculating alpha-diversity. (Sh, BP, Si, ISi or F)

## 7. run_prokka.sh
Runs [Prokka](https://github.com/tseemann/prokka) on the assembled genomes.

- `-i INPUT_DIR` Path to the input directory. Input structure should be the same as for run_kraken2.sh
- `-o OUTPUT_DIR` Path to the output directory
- `-t THREADS` Number of CPU threads to use (default: 8)

## 8. run_keggcharter.sh

Runs [KEGGCharter](https://github.com/iquasere/KEGGCharter) on the Prokka .tsv output files. Also adds the most commonly found bacteria species from the respective Kraken reports to those files and afterwards cleans it for input to the database.

- `-i INPUT_DIR` Path to the input directory containing Prokka files. Expected input structure below.
- `-o OUTPUT_DIR` Path to the output directory
- `-k KRAKEN_DIR` Path to the Kraken reports directory, all reports should be contained in a single directory and match the names in the input directory
- `-s SCRIPT_DIR` Path to the folder containing scripts `clean_file.py` and `select_species.py`
- `-t THREADS` Number of CPU threads to use (default:8)


```
parent_data_folder/  
├── sample_01/  
│   └── sample_01.tsv
├── sample_02/  
│   └── sample_02.tsv
└── ...
```
### select_species.py
Takes a Kraken report and a Prokka .tsv file and assigns the most common bacteria species as the taxon to the Prokka file.
### clean_file.py
Takes KEGGCharter_results.tsv file from KEGGCharter as input and cleans it by dropping duplicates, RNA-s and hypothetical proteins.

## 9. run_roary.sh
Runs [Roary](https://github.com/sanger-pathogens/Roary) to calculate the pan-genome.

- `-i INPUT_DIR` Path to the input directory containing Prokka files. Expected input structure same as for run_keggcharter.sh
- `-o OUTPUT_DIR` Path to the output directory
- `-t THREADS` Number of CPU threads to use (default:8)
- `--samples` Space-separated sample names to combine

## 10. run_quast.sh
Runs [Quast](https://github.com/ablab/quast).

- `-i INPUT_DIR` Path to the input directory. Input structure should be the same as for run_kraken2.sh
- `-o OUTPUT_DIR` Path to the output directory
- `-t THREADS` Number of CPU threads to use (default: 4)

## 11. run_abricate.sh
Runs [Abricate](https://github.com/tseemann/abricate) on the assembled genomes.

- `-d DATABASES` Space-separated list of databases for Abricate to use. By default uses all the default ones.
- `-i INPUT_DIR` Path to the input directory. Input structure should be the same as for run_kraken2.sh
- `-o OUTPUT_DIR` Path to the output directory
- `-m MINID` Minimum identity percentage (0 to 100)
- `-c MINCOV` Minimum coverage percentage (0 to 100)

## 12. run_integron_finder.sh
Runs [Integron Finder](https://github.com/gem-pasteur/Integron_Finder).

- `-i INPUT_DIR` Path to the input directory. Input structure should be the same as for run_kraken2.sh
- `-o OUTPUT_DIR` Path to the output directory
- `-t THREADS` Number of CPU threads to use (default: 4)

## 13. run_isescan.sh
Runs [ISEScan](https://github.com/xiezhq/ISEScan).

- `-i INPUT_DIR` Path to the input directory. Input structure should be the same as for run_kraken2.sh
- `-o OUTPUT_DIR` Path to the output directory
- `-t THREADS` Number of CPU threads to use (default: 8)

## 14. extract_abstracts.py

Takes an input JSON XML file from [Entrez Esearch](https://www.ncbi.nlm.nih.gov/books/NBK25499/) and retrieves all the abstracts for the id-s using Efetch. Then creates a JSON from them. 