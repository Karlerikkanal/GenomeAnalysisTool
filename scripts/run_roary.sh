#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 [-i INPUT_DIR] [-o OUTPUT_DIR] [-t THREADS] --samples <sample1 sample2 ...>"
    echo "  -i INPUT_DIR    Directory with Prokka output (default: $INPUT_DIR)"
    echo "  -o OUTPUT_DIR    Base output directory for Roary (default: $OUTPUT_DIR)"
    echo "  -t THREADS       Number of CPU threads (default: $THREADS)"
    echo "  --samples        Space-separated sample names to combine (required)"
    exit 1
}

# Parse args (support long options)
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t)
            THREADS="$2"
            shift 2
            ;;
        --samples)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                SAMPLES+=("$1")
                shift
            done
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/prokka_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/roary_out}"
THREADS="${THREADS:-$THREADS}"
SAMPLES="${SAMPLES:-$ROARY_genomes}"
SAMPLES=($SAMPLES)

if [[ ${#SAMPLES[@]} -eq 0 ]]; then
    echo "Error: You must provide at least one sample using --samples."
    usage
fi

# Join sample names with underscores to create output dir
LIST_NAME=$(IFS=_; echo "${SAMPLES[*]}")
OUTPUT_DIR="$OUTPUT_DIR/$LIST_NAME"

# Remove output dir if it already exists
if [[ -d "$OUTPUT_DIR" ]]; then
    rm -rf "$OUTPUT_DIR"
fi

# Collect GFF files
GFF_FILES=()
for sample in "${SAMPLES[@]}"; do
    gff_file="$INPUT_DIR/$sample/$sample.gff"
    if [[ -f "$gff_file" ]]; then
        GFF_FILES+=("$gff_file")
    else
        echo "Warning: No .gff file found for sample '$sample' in $INPUT_DIR"
    fi
done

if [[ ${#GFF_FILES[@]} -eq 0 ]]; then
    echo "Error: No valid .gff files found for the provided samples. Exiting."
    exit 1
fi

# Run Roary
echo "Running Roary on ${#GFF_FILES[@]} genome files..."
roary -e -n -p "$THREADS" -f "$OUTPUT_DIR" "${GFF_FILES[@]}"

if [[ $? -eq 0 ]]; then
    echo "Roary completed successfully. Results are in $OUTPUT_DIR"
else
    echo "Roary encountered an error."
fi
