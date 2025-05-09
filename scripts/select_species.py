import pandas as pd
import argparse

def main():
    parser = argparse.ArgumentParser(description="Process a Kraken report to get taxonomic column.")
    parser.add_argument("kraken_input", help="Path to the Kraken input file.")
    parser.add_argument("prokka_input", help="Path to the Prokka input file")
    args = parser.parse_args()
    kraken_file = args.kraken_input
    prokka_file = args.prokka_input
    # Read in report
    kraken_df = pd.read_csv(kraken_file, sep="\t", header=None, names=[
        "percentage", "reads_count", "taxon_reads_count", "rank_code", "ncbi_taxid", "scientific_name"
    ])
    kraken_df["scientific_name"] = kraken_df["scientific_name"].str.strip()
    bacteria_index = kraken_df[kraken_df["scientific_name"] == "Bacteria"].index

    if not bacteria_index.empty:
        # Keep all rows after Bacteria
        bacteria_df = kraken_df.loc[bacteria_index[0]:]
    else:
        # If not found return unclassified
        return "unclassified"
    
    # Remove everything below "Eukaryota" if it appears
    eukaryota_index = bacteria_df[bacteria_df["scientific_name"] == "Eukaryota"].index

    if not eukaryota_index.empty:
        bacteria_df = bacteria_df.loc[:eukaryota_index[0]-1].copy()
    top_bacteria_species = bacteria_df[bacteria_df["rank_code"] == "S"].sort_values(by="reads_count", ascending=False)

    if not top_bacteria_species.empty:
        # Select the most classified species
        selected_taxon = top_bacteria_species.iloc[0]["scientific_name"]
    else:
        # If no species found, select the highest ranked bacterial classification
        filtered_bacteria_df = bacteria_df[bacteria_df["scientific_name"] != "Bacteria"]
        selected_taxon = filtered_bacteria_df.sort_values(by="reads_count", ascending=False).iloc[0]["scientific_name"]
    if not selected_taxon:
        selected_taxon == "unclassified"
    # Write found taxon to Prokka file
    prokka_df = pd.read_csv(prokka_file, sep="\t")
    prokka_df["taxonomy"] = selected_taxon
    prokka_df.to_csv(args.prokka_input, sep="\t") 
    print(selected_taxon)
    return selected_taxon



if __name__ == "__main__":
    main()
