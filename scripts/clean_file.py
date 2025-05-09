import argparse
import pandas as pd
import numpy as np
from pathlib import Path  


def main():
    parser = argparse.ArgumentParser(description="Process a KEGGCharter file for input to model.")
    parser.add_argument("input_file", help="Path to the input file.")
    parser.add_argument("out_file", help="Path to the output directory.")
    args = parser.parse_args()
    out_data = process_file(args.input_file)
    filepath = Path(args.out_file)  
    filepath.parent.mkdir(parents=True, exist_ok=True)
    out_data.to_csv(filepath, index=False, na_rep='')



def process_file(tsv_file):
    data = pd.read_csv(tsv_file, sep = '\t')
    data = data.replace(r'^\s*$', np.nan, regex=True)
    filtered_data = data[data['product'] != 'hypothetical protein']
    filtered_data = filtered_data[~filtered_data['ftype'].str.contains("RNA", case=False, na=False)]
    filtered_data = filtered_data.drop_duplicates('EC_number')
    filtered_data = filtered_data.drop_duplicates('COG')
    return filtered_data

if __name__ == "__main__":
    main()