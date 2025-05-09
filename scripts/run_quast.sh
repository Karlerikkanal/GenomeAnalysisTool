#!/bin/bash
trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 -i INPUT_DIR -o OUTPUT_DIR -t THREADS"
    echo "  -i INPUT_DIR   Path to the input directory"
    echo "  -o OUTPUT_DIR  Path to the output directory"
    echo "  -t THREADS     Number of CPU threads"
    exit 1
}

while getopts "i:o:t:" opt; do
    case "$opt" in
        i) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        *) usage ;;
    esac
done

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/megahit_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/quast_out}"
THREADS="${THREADS:-$THREADS}"

mkdir -p "$OUTPUT_DIR"

# Loop through all the contigs from the input directory
find "$INPUT_DIR" -type f -name "final.contigs.fa" | while read -r contig_file; do
    sample_name=$(basename "$(dirname "$contig_file")")
    sample_output_dir="$OUTPUT_DIR/$sample_name"

    # Check if QUAST has already been run for this sample
    if [ -d "$sample_output_dir" ] && [ -f "$sample_output_dir/report.txt" ]; then
        echo "QUAST already completed for $sample_name. Skipping..."
        continue
    fi
    echo "Running QUAST for sample: $sample_name"
    quast "$contig_file" \
        -o "$sample_output_dir" \
        --threads "$THREADS"
    if [ $? -eq 0 ]; then
        echo "Finished QUAST for $sample_name"
    else
        echo "QUAST failed for $sample_name."
    fi

done

echo "All QUAST analyses are complete!"

