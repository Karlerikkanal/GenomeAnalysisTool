import argparse
import requests
import json
from bs4 import BeautifulSoup

def main():

    parser = argparse.ArgumentParser(description="Process string from Esearch request and create JSON with ID-s and their abstracts")
    parser.add_argument("input_file", help="Input JSON file")
    parser.add_argument("out_file", help="Path to the output JSON file.")
    args = parser.parse_args()
    # Load the XML string from JSON
    with open(args.input_file, "r", encoding="utf-8") as f:
        input_data = json.load(f)
    xml_string = input_data[0]['data']
    xml_data = BeautifulSoup(xml_string, "xml")
    ids = [id_tag.text for id_tag in xml_data.find_all("Id")]
    abstracts = []
    # For each id, do an API call and extract the abstract from it
    for id in ids:
        url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id={id}&retmode=xml"
        page = requests.get(url)
        content = page.text
        soup = BeautifulSoup(content, "html.parser")
        abstract_tags = soup.find_all("abstracttext")
        abstract = " ".join(tag.text.strip() for tag in abstract_tags)
        abstracts.append(
            {
                "id": id,
                "abstract": abstract
            }
        )
    with open(args.out_file, "w", encoding="utf-8") as f:
        json.dump(abstracts, f, indent=2, ensure_ascii=False)
if __name__ == "__main__":
    main()