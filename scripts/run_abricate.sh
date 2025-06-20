#!/bin/bash
trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/GenomeAnalysisTool/default_config.sh

usage() {
    echo "Usage: $0 -d \"db1 db2 db3\" [-i INPUT_DIR] [-o OUTPUT_DIR] [-m MINID] [-c MINCOV]"
    echo "  -d DATABASES   Space-separated list of databases to use"
    echo "  -i INPUT_DIR   Path to the input directory"
    echo "  -o OUTPUT_DIR  Path to the output directory"
    echo "  -m MINID       Minimum identity percentage"
    echo "  -c MINCOV      Minimum coverage percentage"
    echo "  -f CONFIG_FILE Config file to source"
    exit 1
}

while getopts "d:i:o:m:c:f:" opt; do
    case "$opt" in
        d) IFS=' ' read -r -a DATABASES <<< "$OPTARG" ;;
        i) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        m) MINID="$OPTARG" ;;
        c) MINCOV="$OPTARG" ;;
        f) CONFIG_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -n "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/megahit_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/abricate_out}"
DEFAULT_DATABASES=("megares" "ncbi" "plasmidfinder" "argannot" "resfinder" "card" "ecoli_vf" "vfdb" "ecoh")
MINID="${MINID:-$ABRICATE_minid_per}"
MINCOV="${MINCOV:-$ABRICATE_minid_cov}"

# If no databases were provided, use default databases
if [[ -z "$ABRICATE_db_list" ]]; then
    DATABASES=("${DEFAULT_DATABASES[@]}")
else
    IFS=' ' read -r -a DATABASES <<< "$ABRICATE_db_list"
fi

echo "${DATABASES[@]}"
mkdir -p "$OUTPUT_DIR"

# Loop through all contig files from input directory
find "$INPUT_DIR" -type f -name "final.contigs.fa" | while read -r contig_file; do
    sample_name=$(basename "$(dirname "$contig_file")")
    sample_output_dir="$OUTPUT_DIR/$sample_name"
    mkdir -p "$sample_output_dir"

    # Loop through each database
    for ABRICATE_DB in "${DATABASES[@]}"; do
        abricate_output_file="$sample_output_dir/${ABRICATE_DB}.abricate.tsv"

        # Check if Abricate has already been run for this sample and database
        if [ -f "$abricate_output_file" ]; then
            echo "Abricate already completed for $sample_name with $ABRICATE_DB. Skipping..."
            continue
        fi

        echo "Running Abricate for sample: $sample_name with database: $ABRICATE_DB"

        abricate --db "$ABRICATE_DB" --minid "$MINID" --mincov "$MINCOV" "$contig_file" > "$abricate_output_file"

        if [ $? -eq 0 ]; then
            echo "Finished Abricate for $sample_name with $ABRICATE_DB"
        else
            echo "Abricate failed for $sample_name with $ABRICATE_DB."
        fi
    done
done

# Generate a summary file for all results
echo "Generating summary file for all Abricate results..."
abricate --summary "$OUTPUT_DIR"/*/*.abricate.tsv > "$OUTPUT_DIR/abricate_summary.tsv"

echo "All Abricate analyses are complete!"
echo "Summary file created at: $OUTPUT_DIR/abricate_summary.tsv"

