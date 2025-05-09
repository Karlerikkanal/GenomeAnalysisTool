#!/bin/bash
trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/config.sh

usage() {
    echo "Usage: $0 [-i INPUT_DIR] [-o OUTPUT_DIR] [-t THREADS]"
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
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/isescan_out}"
THREADS="${THREADS:-$THREADS}"

mkdir -p "$OUTPUT_DIR"

echo "Starting ISEScan analysis..."

# Loop through all contigs in input
find "$INPUT_DIR" -type f -name "final.contigs.fa" | while read -r contig_file; do
    sample_name=$(basename "$(dirname "$contig_file")")
    sample_output_dir="$OUTPUT_DIR/$sample_name/$sample_name"

    # Check if ISEScan has already been run for this sample
    if [[ -d "$sample_output_dir" ]] && [[ -f "$sample_output_dir/final.contigs.fa.sum" ]] && [[ -f "$sample_output_dir/final.contigs.fa.orf.faa" ]]; then
        echo "ISEScan already completed for $sample_name. Skipping..."
        continue
    fi

    echo "Running ISEScan for sample: $sample_name"

    isescan.py --seqfile "$contig_file" --output "$OUTPUT_DIR/$sample_name" --nthread "$THREADS"

    if [ $? -eq 0 ]; then
        echo "Finished ISEScan for $sample_name"
    else
        echo "ISEScan failed for $sample_name."
    fi
done

echo "All ISEScan analyses are complete!"

