#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 -i INPUT_DIR -o OUTPUT_DIR [-p true|false]"
    echo "  -i INPUT_DIR   Path to the input directory"
    echo "  -o OUTPUT_DIR  Path to the output directory"
    echo "  -p true|false  Whether reads are paired-end (default: true)"
    exit 1
}

while getopts "i:o:p:" opt; do
    case "$opt" in
        i) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        p) PAIRED="$OPTARG" ;;
        *) usage ;;
    esac
done

INPUT_DIR="${INPUT_DIR:-$BASE_INPUT_DIR}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/trim_out}"
PAIRED="${PAIRED:-$TRIMGALORE_paired}"

echo $OUTPUT_DIR

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Error: Both input and output directories must be specified."
    usage
fi

mkdir -p "$OUTPUT_DIR"
echo "Starting Trim Galore! Mode: $([ "$PAIRED" == "true" ] && echo "Paired-end" || echo "Single-end")"

# Loop through all subdirectories
for SUBDIR in "$INPUT_DIR"/*/; do
    SAMPLE_NAME=$(basename "$SUBDIR")
    SAMPLE_OUTPUT="$OUTPUT_DIR/$SAMPLE_NAME"
    echo $SAMPLE_OUTPUT
    mkdir -p "$SAMPLE_OUTPUT"

    if [[ "$PAIRED" == "true" ]]; then
        R1_FILE=$(find "$SUBDIR" -type f -name "*_R1.fastq.gz" | head -n 1)
        R2_FILE=$(find "$SUBDIR" -type f -name "*_R2.fastq.gz" | head -n 1)
        R1_BASENAME=$(basename "$R1_FILE" .fastq.gz)
        R2_BASENAME=$(basename "$R2_FILE" .fastq.gz)
        TRIMMED_R1="$SAMPLE_OUTPUT/${R1_BASENAME}_val_1.fq.gz"
        TRIMMED_R2="$SAMPLE_OUTPUT/${R2_BASENAME}_val_2.fq.gz"

        if [[ -f "$TRIMMED_R1" && -f "$TRIMMED_R2" ]]; then
            echo "Skipping $SAMPLE_NAME: already processed."
            continue
        fi

        if [[ -n "$R1_FILE" && -n "$R2_FILE" ]]; then
            echo "Processing $SAMPLE_NAME (paired-end):"
            echo "  R1: $R1_FILE"
            echo "  R2: $R2_FILE"
            trim_galore --paired --quality 20 --length 50 --fastqc -o "$SAMPLE_OUTPUT" "$R1_FILE" "$R2_FILE"
            echo "Finished processing $SAMPLE_NAME"
        else
            echo "Paired files not found in $SUBDIR. Skipping."
        fi

    else  # Single-end mode
        SEQ_FILE=$(find "$SUBDIR" -type f -name "*.fastq.gz" ! -name "*_R2.fastq.gz" ! -name "*_R1.fastq.gz" | head -n 1)
        TRIMMED_FILE="$SAMPLE_OUTPUT/$(basename "$SEQ_FILE" .fastq.gz)_trimmed.fq.gz"

        if [[ -f "$TRIMMED_FILE" ]]; then
            echo "Skipping $SAMPLE_NAME: already processed."
            continue
        fi

        if [[ -n "$SEQ_FILE" ]]; then
            echo "Processing $SAMPLE_NAME (single-end):"
            echo "  File: $SEQ_FILE"
            trim_galore --quality 20 --length 50 --fastqc -o "$SAMPLE_OUTPUT" "$SEQ_FILE"
            echo "Finished processing $SAMPLE_NAME"
        else
            echo "No valid single-end FASTQ file found in $SUBDIR. Skipping."
        fi
    fi
done

echo "All samples have been processed."
