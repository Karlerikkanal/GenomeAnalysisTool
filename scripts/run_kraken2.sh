#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 [-i INPUT_DIR] [-o OUTPUT_DIR] [-d KRAKEN2_DB] [-c CONFIDENCE] [-t THREADS] [-p true/false]"
    echo "  -i INPUT_DIR    Path to the input directory"
    echo "  -o OUTPUT_DIR   Path to the output directory"
    echo "  -d KRAKEN2_DB   Path to the Kraken2 database"
    echo "  -c CONFIDENCE   Confidence threshold"
    echo "  -t THREADS      Number of CPU threads"
    echo "  -p PAIRED       Set to 'true' for paired-end read analysis, 'false' for assembled contigs"
    exit 1
}

while getopts "i:o:d:c:t:p:" opt; do
    case "$opt" in
        i) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        d) KRAKEN2_DB="$OPTARG" ;;
        c) CONFIDENCE="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        p) PAIRED="$OPTARG" ;;
        *) usage ;;
    esac
done

OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/kraken2_out}"
KRAKEN2_DB="${KRAKEN2_DB:-$KRAKEN_DB}"
CONFIDENCE="${CONFIDENCE:-$KRAKEN_pvalue}"
THREADS="${THREADS:-$THREADS}"
PAIRED="${PAIRED:-$KRAKEN_paired}"

if [[ -z "$INPUT_DIR" ]]; then
    if [[ "$PAIRED" == "true" ]]; then
        INPUT_DIR="$BASE_OUTPUT_DIR/trim_out"
    else
        INPUT_DIR="$BASE_OUTPUT_DIR/megahit_out"
    fi
fi

COMBINE_SCRIPT="$HOME/KrakenTools/combine_kreports.py"
COMBINED_DIR="$OUTPUT_DIR/combined_kraken2_reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMBINED_FILE="$COMBINED_DIR/combined_kraken2_${TIMESTAMP}.kreport"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$COMBINED_DIR"

echo "Starting Kraken2 analysis..."
echo "Input Directory: $INPUT_DIR"
echo "Output Directory: $OUTPUT_DIR"
echo "Paired-end mode: $PAIRED"

if [[ "$PAIRED" == "true" ]]; then
    echo "Running Kraken2 in paired-end mode..."
    # Loop through all sample directories in the input directory
    for SAMPLE_DIR in "$INPUT_DIR"/*; do
        SAMPLE_NAME=$(basename "$SAMPLE_DIR")
        R1_FILE=$(find "$SAMPLE_DIR" -type f -name "*_R1_val_1.fq.gz" | head -n 1)
        R2_FILE=$(find "$SAMPLE_DIR" -type f -name "*_R2_val_2.fq.gz" | head -n 1)
        SAMPLE_OUTPUT_FILE="$OUTPUT_DIR/$SAMPLE_NAME.kraken2_report"
        
	# Check if already run on same files
        if [[ -f "$SAMPLE_OUTPUT_FILE" ]]; then
            echo "Skipping $SAMPLE_NAME: Kraken2 analysis already completed."
            continue
        fi

        # Check if both paired-end files exist and then run
        if [[ -f "$R1_FILE" && -f "$R2_FILE" ]]; then
            echo "Running Kraken2 for sample: $SAMPLE_NAME..."

            kraken2 --db "$KRAKEN2_DB" \
                --paired \
                --output "$OUTPUT_DIR/$SAMPLE_NAME.kraken2_output" \
                --report "$SAMPLE_OUTPUT_FILE" \
                --confidence "$CONFIDENCE" \
                --threads "$THREADS" \
                "$R1_FILE" "$R2_FILE"

            if [ $? -eq 0 ]; then
                echo "Finished Kraken2 analysis for $SAMPLE_NAME."
            else
                echo "Kraken2 failed for $SAMPLE_NAME."
            fi
        else
            echo "Missing paired files for $SAMPLE_NAME. Skipping."
        fi
    done

else
    echo "Running Kraken2 in single-contig mode..."
    
    find "$INPUT_DIR" -type f -name "final.contigs.fa" | while read -r CONTIG_FILE; do
        SAMPLE_NAME=$(basename "$(dirname "$CONTIG_FILE")")
        SAMPLE_OUTPUT_FILE="$OUTPUT_DIR/$SAMPLE_NAME.kraken2_report"

        if [[ -f "$SAMPLE_OUTPUT_FILE" ]]; then
            echo "Skipping $SAMPLE_NAME: Kraken2 analysis already completed."
            continue
        fi

        echo "Running Kraken2 for sample: $SAMPLE_NAME"

        kraken2 --db "$KRAKEN2_DB" \
            --output "$OUTPUT_DIR/$SAMPLE_NAME.kraken2_output" \
            --report "$SAMPLE_OUTPUT_FILE" \
            --confidence "$CONFIDENCE" \
            --threads "$THREADS" \
            "$CONTIG_FILE"

        if [ $? -eq 0 ]; then
            echo "Finished Kraken2 for $SAMPLE_NAME."
        else
            echo "Kraken2 failed for $SAMPLE_NAME."
        fi
    done
fi

echo "All Kraken2 analyses are complete!"

# Find all .kraken2_report files and run combine_kreports.py
REPORT_FILES=$(find "$OUTPUT_DIR" -type f -name "*.kraken2_report")

if [[ -n "$REPORT_FILES" ]]; then
    echo "Combining Kraken2 reports into: $COMBINED_FILE"
    python3 "$COMBINE_SCRIPT" -r $REPORT_FILES -o "$COMBINED_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Combined Kraken2 report created: $COMBINED_FILE"
    else
        echo "Failed to combine Kraken2 reports."
    fi
else
    echo "No Kraken2 report files found to combine."
fi

