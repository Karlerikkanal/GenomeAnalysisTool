#!/bin/bash

trap "echo 'Script interrupted by user. Exiting...'; exit 1" SIGINT
source $HOME/GenomeAnalysisTool/default_config.sh

usage() {
    echo "Usage: $0 -i INPUT_DIR -k KRAKEN_DIR -o OUTPUT_DIR -s SCRIPT_DIR -t THREADS"
    echo "  -i INPUT_DIR    Directory containing Prokka output"
    echo "  -k KRAKEN_DIR    Directory containing Kraken2 reports"
    echo "  -o OUTPUT_DIR    Directory for KEGGCharter output"
    echo "  -s SCRIPT_DIR    Directory containing helper Python scripts"
    echo "  -t THREADS       Number of CPU threads (default: 8)"
    echo "  -f CONFIG_FILE   Config file to source"
    exit 1
}

while getopts "i:k:o:s:t:f:" opt; do
    case "$opt" in
        i) INPUT_DIR="$OPTARG" ;;
        k) KRAKEN_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        s) SCRIPT_DIR="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        f) CONFIG_FILE="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -n "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

INPUT_DIR="${INPUT_DIR:-$BASE_OUTPUT_DIR/prokka_out}"
KRAKEN_DIR="${KRAKEN_DIR:-$BASE_OUTPUT_DIR/kraken2_out}"
OUTPUT_DIR="${OUTPUT_DIR:-$BASE_OUTPUT_DIR/keggcharter_out}"
SCRIPT_DIR="${SCRIPT_DIR:-$HOME}/GenomeAnalysisTool/scripts"
THREADS="${THREADS:-$THREADS}"

if [[ -z "$INPUT_DIR" || -z "$KRAKEN_DIR" || -z "$OUTPUT_DIR" || -z "$SCRIPT_DIR" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

if [ "$THREADS" -gt 8 ]; then
    THREADS=8
fi

mkdir -p "$OUTPUT_DIR"

# Loop through all Prokka output directories
for sample_dir in "$INPUT_DIR"/*; do
    if [[ -d "$sample_dir" ]]; then
        sample_name=$(basename "$sample_dir")
        prokka_file="$sample_dir/$sample_name.tsv"
        sample_output_dir="$OUTPUT_DIR/$sample_name"
        kraken_file="$KRAKEN_DIR/$sample_name.kraken2_report"
        keggcharter_results="$sample_output_dir/KEGGCharter_results.tsv"

        # Check if KEGGCharter has already been run for this sample
        if [[ -f "$keggcharter_results" ]]; then
            echo "Skipping $sample_name: KEGGCharter already completed for this file."
            continue
        fi

        # Check if both TSV and Kraken2 files exist
        if [[ -f "$prokka_file" && -f "$kraken_file" ]]; then
            echo "Processing sample: $sample_name"
            # Extract most classified species from Kraken2 report
            echo "Running Python script: python3 $SCRIPT_DIR/select_species.py $kraken_file"
            top_species=$(python3 "$SCRIPT_DIR/select_species.py" "$kraken_file" "$prokka_file")
            
            if [[ -z "$top_species" ]]; then
                top_species="unclassified"
            fi
            
            echo "Using taxonomy: $top_species"

            # Run KEGGCharter with the extracted taxonomy
            keggcharter -f "$prokka_file" -rd "data/kegg-resources" -o "$sample_output_dir" \
                        -ecc 'EC_number' -cogc 'COG' -tc "taxonomy" -iq -t "$THREADS"

            if [ $? -eq 0 ]; then
                echo "KEGGCharter completed successfully for $sample_name"

                # Run clean_file.py after KEGGCharter. Skip if already in output_dir to avoid multiple uploads to database.
                OUTPUT_CSV="$HOME/data/mudeli_input/${sample_name}.csv"
                if [[ -f "$OUTPUT_CSV" ]]; then
                    echo "Skipping cleaning: $OUTPUT_CSV already exists."
                else
                    echo "Cleaning KEGGCharter output for $sample_name..."
                    python3 "$SCRIPT_DIR/clean_file.py" "$keggcharter_results" "$OUTPUT_CSV"

                    if [ $? -eq 0 ]; then
                        echo "Cleaned data saved to $OUTPUT_CSV"
                    else
                        echo "Cleaning script failed for $sample_name"
                    fi
                fi

                if [ $? -eq 0 ]; then
                    echo "Cleaned data saved to $OUTPUT_CSV"
                else
                    echo "Cleaning script failed for $sample_name"
                fi

            else
                echo "KEGGCharter failed for $sample_name."
                
                # KeggCharter sometimes gets a connection error when creating graphs. In this case, clean and upload the results file anyway.
                OUTPUT_CSV="$HOME/data/mudeli_input/${sample_name}.csv"
                if [[ -f "$OUTPUT_CSV" ]]; then
                    echo "Skipping cleaning: $OUTPUT_CSV already exists."
                else
                    echo "Cleaning KEGGCharter output for $sample_name..."
                    python3 "$SCRIPT_DIR/clean_file.py" "$keggcharter_results" "$OUTPUT_CSV"

                    if [ $? -eq 0 ]; then
                        echo "Cleaned data saved to $OUTPUT_CSV"
                    else
                        echo "Cleaning script failed for $sample_name"
                    fi
                fi

                if [ $? -eq 0 ]; then
                    echo "Cleaned data saved to $OUTPUT_CSV"
                else
                    echo "Cleaning script failed for $sample_name"
                fi
            fi
        else
            echo "TSV or Kraken2 file missing for $sample_name. Skipping..."
        fi
    fi
done

echo "All KEGGCharter analyses are complete!"

