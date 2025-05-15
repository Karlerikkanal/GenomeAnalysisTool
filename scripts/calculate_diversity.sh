#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 -i INPUT_DIR -o OUTPUT_DIR"
    echo "  -i INPUT_DIR   Directory with .bracken files"
    echo "  -o OUTPUT_DIR  Directory to store diversity results"
    echo "  -f FILTERED    If filter_bracken_out was applied before this script, changes input directory accordingly"
    echo "  -d DIVERSITY_TYPE The diversity type for calculating alpha-diversity. (Sh, BP, Si, ISi or F)"
    exit 1
}

while getopts "i:o:f:" opt; do
  case "$opt" in
    i) INPUT_DIR="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    f) FILTERED="$OPTARG" ;;
    d) DIVERSITY_TYPE="$OPTARG" ;;
    *) usage ;;
  esac
done

BASE_OUT_DIR="${BASE_OUT_DIR:-$BASE_OUTPUT_DIR}"
INPUT_DIR="${INPUT_DIR:-$BASE_OUT_DIR/bracken_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUT_DIR/diversity_out}"
FILTERED="${FILTERED:-false}"
DIVERSITY_TYPE="${DIVERSITY_TYPE:-$DIVERSITY_type}"

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: Both input and output directories must be specified."
    usage
fi

if [[ "$FILTERED" == "true" ]]; then
  INPUT_DIR="$BASE_OUT_DIR/filtered_bracken_out"
fi

mkdir -p "$OUTPUT_DIR"

ALPHA_DIVERSITY_OUTPUT="$OUTPUT_DIR/alpha_diversity.tsv"
BETA_DIVERSITY_OUTPUT="$OUTPUT_DIR/beta_diversity.tsv"

# Loop through filtered Bracken output files for alpha diversity
echo "Calculating alpha diversity..."
find "$INPUT_DIR" -type f -name "*.bracken" | while read -r bracken_file; do

    sample_name=$(basename "$bracken_file" .bracken)
    alpha_output_file="$OUTPUT_DIR/${sample_name}_alpha.txt"

    # Calculate alpha diversity
    python KrakenTools/DiversityTools/alpha_diversity.py -a $DIVERSITY_TYPE -f "$bracken_file" > "$alpha_output_file"

    if [ $? -eq 0 ]; then
        echo "Alpha diversity analysis completed for $sample_name"
    else
        echo "Alpha diversity analysis failed for $sample_name."
    fi
done

cat "$OUTPUT_DIR"/*_alpha.txt > "$ALPHA_DIVERSITY_OUTPUT"

# Run beta diversity analysis
echo "Running beta diversity analysis..."
python KrakenTools/DiversityTools/beta_diversity.py -i "$INPUT_DIR"/*.bracken --type bracken --level S > "$BETA_DIVERSITY_OUTPUT"

if [ $? -eq 0 ]; then
    echo "Beta diversity analysis completed successfully!"
else
    echo "Beta diversity analysis failed."
fi

echo "All diversity analyses completed!"

