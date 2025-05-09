#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 [-i INPUT_DIR] [-o OUTPUT_DIR] [-d BRACKEN_DB] [-r READ_LEN] [-l LEVEL] [-t THRESHOLD]"
    echo "  -i INPUT_DIR       Directory containing Kraken2 reports"
    echo "  -o OUTPUT_DIR      Output directory for Bracken results"
    echo "  -d BRACKEN_DB      Path to Bracken database"
    echo "  -r READ_LEN        Read length (default: 100)"
    echo "  -l LEVEL           Taxonomic level (default: S)"
    echo "  -t THRESHOLD       Minimum abundance threshold (default: 10)"
    exit 1
}

while getopts "i:o:d:r:l:t:" opt; do
    case "$opt" in
        i) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        d) BRACKEN_DB="$OPTARG" ;;
        r) READ_LEN="$OPTARG" ;;
        l) LEVEL="$OPTARG" ;;
        t) THRESHOLD="$OPTARG" ;;
        *) usage ;;
    esac
done

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/kraken2_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/bracken_out}"
BRACKEN_DB="${BRACKEN_DB:-$KRAKEN_DB}"
READ_LEN="${READ_LEN:-$BRACKEN_readlen}"
LEVEL="${LEVEL:-$BRACKEN_taxonomy}"
THRESHOLD="${THRESHOLD:-$BRACKEN_ab_threshold}"

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" || -z "$BRACKEN_DB" ]]; then
    echo "Error: Required paths missing."
    usage
fi

mkdir -p "$OUTPUT_DIR"

# Loop through all Kraken2 report files in the Kraken2 output directory
find "$INPUT_DIR" -type f -name "*.kraken2_report" | while read -r report_file; do
    # Extract the sample name from the report file
    sample_name=$(basename "$report_file" .kraken2_report)
    bracken_output_file="$OUTPUT_DIR/$sample_name.bracken"

    # Check if Bracken has already been run for this sample
    if [ -f "$bracken_output_file" ]; then
        echo "Bracken already completed for $sample_name. Skipping..."
        continue
    fi

    # Run Bracken for the sample
    echo "Running Bracken for sample: $sample_name"

    bracken -d "$BRACKEN_DB" \
            -i "$report_file" \
            -o "$bracken_output_file" \
            -r "$READ_LEN" \
            -l "$LEVEL" \
            -t "$THRESHOLD" \
            -w "$OUTPUT_DIR/$sample_name.bracken_species"

    if [ $? -eq 0 ]; then
        echo "Finished Bracken for $sample_name"
    else
        echo "Bracken failed for $sample_name."
    fi
done

echo "All Bracken analyses are complete!"
