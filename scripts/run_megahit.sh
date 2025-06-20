#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/GenomeAnalysisTool/default_config.sh

usage() {
    echo "Usage: $0 -i INPUT_DIR -o OUTPUT_DIR -b BATCH_SIZE -t THREADS [--groups group1,group2;group3,group4]"
    echo "  -i INPUT_DIR     Path to the input directory"
    echo "  -o OUTPUT_DIR    Path to the base output directory"
    echo "  -b BATCH_SIZE    Number of samples per MEGAHIT batch"
    echo "  -t THREADS       Number of CPU threads for MEGAHIT"
    echo "  -f CONFIG_FILE   Config file to source"
    echo "  --groups         Optional: custom groupings as 'strain1,strain2;strain3,strain4'"
    exit 1
}

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i) INPUT_DIR="$2"; shift 2 ;;
        -o) OUTPUT_DIR="$2"; shift 2 ;;
        -b) BATCH_SIZE="$2"; shift 2 ;;
        -t) THREADS="$2"; shift 2 ;;
        -f) CONFIG_FILE="$2"; shift 2 ;;
        --groups) CUSTOM_GROUPS="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

if [[ -n "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/trim_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/megahit_out}"
BATCH_SIZE="${BATCH_SIZE:-$MEGAHIT_batches}"
THREADS="${THREADS:-$THREADS}"
CUSTOM_GROUPS="${CUSTOM_GROUPS:-$MEGAHIT_folders}"

mkdir -p "$OUTPUT_DIR"

samples=($(ls "$INPUT_DIR"))
group_batches=()

if [[ -n "$CUSTOM_GROUPS" ]]; then
    echo "Running in custom grouping mode..."
    
    # Split by semicolon to get group strings
    CUSTOM_GROUPS="$(echo "$CUSTOM_GROUPS" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    CUSTOM_GROUPS="$(echo "$CUSTOM_GROUPS" | sed 's/ *; */;/g')"

    IFS=';' read -ra GROUP_STRINGS <<< "$CUSTOM_GROUPS"
    
    for group_str in "${GROUP_STRINGS[@]}"; do
        if [[ -n "$group_str" ]]; then
            # Split each group by comma into an array of samples
            IFS=',' read -ra group <<< "$group_str"
            group_batches+=("${group[*]}")  # Space-separated group string
        fi
    done
else
    # Assemble batches based on i
    echo "Running in default batching mode (batch size: $BATCH_SIZE)..."
    for ((i=0; i<${#samples[@]}; i+=BATCH_SIZE)); do
        group_batches+=("${samples[@]:i:BATCH_SIZE}")
    done
fi

# Process each group
for batch in "${group_batches[@]}"; do
    read -ra group <<< "$(echo "$batch" | xargs)"
    batch_name=$(IFS=_; echo "${group[*]}")
    output_dir="$OUTPUT_DIR/$batch_name"

    if [[ -d "$output_dir" && -f "$output_dir/final.contigs.fa" ]]; then
        echo "Skipping $batch_name: already completed."
        continue
    fi

    echo "Running MEGAHIT on batch: ${group[*]}"

    left_reads=()
    right_reads=()

    for sample in "${group[@]}"; do
        left_file=$(find "$INPUT_DIR/$sample" -maxdepth 1 -type f -name "*_R1_val_1.fq.gz" | head -n 1)
        right_file=$(find "$INPUT_DIR/$sample" -maxdepth 1 -type f -name "*_R2_val_2.fq.gz" | head -n 1)

        if [[ -f "$left_file" && -f "$right_file" ]]; then
            left_reads+=("$left_file")
            right_reads+=("$right_file")
        else
            echo "Warning: Missing files for $sample, skipping..."
        fi
    done

    left_joined=$(IFS=, ; echo "${left_reads[*]}")
    right_joined=$(IFS=, ; echo "${right_reads[*]}")

    if [[ -z "$left_joined" || -z "$right_joined" ]]; then
        echo "Skipping batch $batch_name due to missing input files."
        continue
    fi

    megahit -1 "$left_joined" -2 "$right_joined" -o "$output_dir" -t "$THREADS"
    echo "Finished batch: $batch_name"
done

echo "All MEGAHIT batches completed!"
