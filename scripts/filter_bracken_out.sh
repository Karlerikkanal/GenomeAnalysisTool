#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source "$HOME/config.sh"

usage() {
    echo "Usage: $0 [-i BRACKEN_OUTPUT_DIR] [-o FILTERED_OUTPUT_DIR] [--include TAXID1 TAXID2 ...] [--exclude TAXID3 TAXID4 ...]"
    echo "  -i BRACKEN_OUTPUT_DIR       Directory containing Bracken output files"
    echo "  -o FILTERED_OUTPUT_DIR      Directory to store filtered results"
    echo "  --include TAXID1 TAXID2     Space-separated taxonomy IDs to include (optional)"
    echo "  --exclude TAXID3 TAXID4     Space-separated taxonomy IDs to exclude (optional)"
    echo
    echo "Note: You must specify either --include or --exclude. You cannot use both with overlapping taxids."
    exit 1
}

# Initialize arrays
INCLUDE_TAXIDS=()
EXCLUDE_TAXIDS=()

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i)
            BRACKEN_OUTPUT_DIR="$2"
            shift 2
            ;;
        -o)
            FILTERED_BRACKEN_OUTPUT_DIR="$2"
            shift 2
            ;;
        --include)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                INCLUDE_TAXIDS+=("$1")
                shift
            done
            ;;
        --exclude)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                EXCLUDE_TAXIDS+=("$1")
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

# Assign defaults from config if not provided from command line
BRACKEN_OUTPUT_DIR="${BRACKEN_OUTPUT_DIR:-$BASE_OUTPUT_DIR/bracken_out}"
FILTERED_BRACKEN_OUTPUT_DIR="${FILTERED_BRACKEN_OUTPUT_DIR:-$BASE_OUTPUT_DIR/filtered_bracken_out}"

# Convert config values (if any) into arrays
if [[ ${#INCLUDE_TAXIDS[@]} -eq 0 && -n "$BRACKEN_include_ids" ]]; then
    read -r -a INCLUDE_TAXIDS <<< "$BRACKEN_include_ids"
fi
if [[ ${#EXCLUDE_TAXIDS[@]} -eq 0 && -n "$BRACKEN_exclude_ids" ]]; then
    read -r -a EXCLUDE_TAXIDS <<< "$BRACKEN_exclude_ids"
fi

# Sanity check
if [[ ${#INCLUDE_TAXIDS[@]} -eq 0 && ${#EXCLUDE_TAXIDS[@]} -eq 0 ]]; then
    echo "Error: Must specify at least one of --include or --exclude."
    usage
fi

# Check for overlap
for inc in "${INCLUDE_TAXIDS[@]}"; do
    for exc in "${EXCLUDE_TAXIDS[@]}"; do
        if [[ "$inc" == "$exc" ]]; then
            echo "Error: Taxonomic ID '$inc' cannot be in both include and exclude lists."
            usage
        fi
    done
done

mkdir -p "$FILTERED_BRACKEN_OUTPUT_DIR"

# Process files
find "$BRACKEN_OUTPUT_DIR" -type f -name "*.bracken" | while read -r bracken_file; do
    sample_name=$(basename "$bracken_file" .bracken)
    filtered_output_file="$FILTERED_BRACKEN_OUTPUT_DIR/${sample_name}_filtered.bracken"

    echo "Filtering $sample_name..."

    cmd=(python3 "$HOME/KrakenTools/filter_bracken.out.py" -i "$bracken_file" -o "$filtered_output_file")

    [[ ${#INCLUDE_TAXIDS[@]} -gt 0 ]] && cmd+=(--include "${INCLUDE_TAXIDS[@]}")
    [[ ${#EXCLUDE_TAXIDS[@]} -gt 0 ]] && cmd+=(--exclude "${EXCLUDE_TAXIDS[@]}")

    "${cmd[@]}"

    if [[ $? -eq 0 ]]; then
        echo "Filtered Bracken output saved for $sample_name"
    else
        echo "Filtering failed for $sample_name"
    fi
done

echo "All Bracken filtering completed."
