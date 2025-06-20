#!/bin/bash
trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/GenomeAnalysisTool/default_config.sh

usage() {
    echo "Usage: $0 [-i INPUT_DIR] [-o OUTPUT_DIR] [-t THREADS]"
    echo "  -i INPUT_DIR   Path to the input directory"
    echo "  -o OUTPUT_DIR  Path to the output directory"
    echo "  -t THREADS     Number of CPU threads"
    echo "  -f CONFIG_FILE Config file to source"
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

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/megahit_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/integron_out}"
THREADS="${THREADS:-$THREADS}"

mkdir -p "$OUTPUT_DIR"

echo "Starting IntegronFinder analysis..."

# Loop through all contigs in input directory
find "$INPUT_DIR" -type f -name "final.contigs.fa" | while read -r contig_file; do
    sample_name=$(basename "$(dirname "$contig_file")")
    sample_output_dir="$OUTPUT_DIR/$sample_name"
    results_dir="$sample_output_dir/Results_Integron_Finder_final.contigs"
    # Check if already done for file
    if [ -d "$results_dir" ] && [ -f "$results_dir/final.contigs.summary" ]; then
        echo "IntegronFinder already completed for $sample_name. Skipping..."
        continue
    fi

    echo "Running IntegronFinder for sample: $sample_name"

    integron_finder "$contig_file" --outdir "$sample_output_dir" --local-max --cpu "$THREADS" --mute

    if [ $? -eq 0 ]; then
        echo "Finished IntegronFinder for $sample_name"
    else
        echo "IntegronFinder failed for $sample_name. Please check the logs."
    fi
done

echo "All IntegronFinder analyses are complete!"

