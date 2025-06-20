#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/GenomeAnalysisTool/default_config.sh

usage() {
    echo "Usage: $0 -i INPUT_DIR -o OUTPUT_DIR -t THREADS"
    echo "  -i INPUT_DIR    Path to the input directory (each subfolder should contain final.contigs.fa)"
    echo "  -o OUTPUT_DIR   Path to the output directory for Prokka results"
    echo "  -t THREADS      Number of CPU threads to use (default: 8)"
    echo "  -f CONFIG_FILE  Config file to source"
    exit 1
}

while getopts "i:o:t:f:" opt; do
    case "$opt" in
        i) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        f) CONFIG_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -n "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Assign values from command line or overwrite with config file parameters
INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/megahit_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/prokka_out}"
THREADS="${THREADS:-$THREADS}"


if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: Both input and output directories must be specified."
    usage
fi

mkdir -p "$OUTPUT_DIR"

# Loop through all subdirectories in the input directory
for sample_dir in "$INPUT_DIR"/*/; do
    sample_name=$(basename "$sample_dir")
    fasta_file="$sample_dir/final.contigs.fa"
    sample_output_dir="$OUTPUT_DIR/$sample_name"

    # Skip if FASTA file doesn't exist
    if [[ ! -f "$fasta_file" ]]; then
        echo "Skipping $sample_name: final.contigs.fa not found."
        continue
    fi

    # Skip already processed samples
    if [[ -d "$sample_output_dir" && -f "$sample_output_dir/$sample_name.gbk" ]]; then
        echo "Skipping $sample_name: Prokka already completed."
        continue
    fi

    # Run Prokka
    echo "Running Prokka on $sample_name..."
    prokka --outdir "$sample_output_dir" --prefix "$sample_name" --cpus "$THREADS" "$fasta_file"

    if [ $? -eq 0 ]; then
        echo "Prokka completed successfully for $sample_name"
    else
        echo "Prokka failed for $sample_name. Check logs."
    fi
done

echo "All Prokka annotations are complete!"