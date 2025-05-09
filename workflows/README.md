# Workflows

This is the folder containing n8n workflows.

## 1. Master_workflow.json
This is the master workflow. As input it takes genomic data in this form:
```
parent_data_folder/  
├── sample_01/  
│   ├── sample_01_R1.fastq.gz  
│   └── sample_01_R2.fastq.gz  
├── sample_02/  
│   ├── sample_02_R1.fastq.gz  
│   └── sample_02_R2.fastq.gz  
├── sample_03/  
│   ├── sample_03_R1.fastq.gz  
│   └── sample_03_R2.fastq.gz  
└── ...
```
After trimming adapters, it will assemble them into genomes and run the other programs based on those assembled files. To use, activate the workflow, access the form at http://localhost:5678/form/master-workflow and submit the parameters to start. Feel free to reassemble the order of programs to suit your needs by deleting/changing the links between them.

## 2. Kraken_workflow.json
This is the Kraken workflow. As input, it takes genomic data in the same form as the master workflow. The difference is, that this workflow will not assemble the genomic data and instead run it pair-wise through Kraken and Bracken. Access the form after the workflow is activated at: http://localhost:5678/form/kraken-workflow 

## 3. File_upload.json

This workflow hosts two sub-workflows for uploading files. The first workflow is activated by run_keggcharter.sh and it populates the annotations table. The filepath for the folder should match the one in run_keggcharter.sh which by default is `OUTPUT_CSV="$HOME/database_files`.

The second sub-workflow is for uploading PDF-files to the vector database to be used by the PDF agent. Here the workflow triggers when you upload a PDF file of your choice to the respective folder. **Note:** only PDF-files will get uploaded.

## 4. Master_agent.json
This is the master agent. Use it to chat about the database or ask information about research papers. If the agent starts consistently outputting nonsense, drop the chat history in the database and chat again. The chat history table will automatically be created again. The agent has access to three tools, Abstacts_search_agent, Database_agent and PDF_agent which are described in their respective sections.

## 5. Database_agent.json

This is an agent designed to interact with your relational database. It has access to three tools: 1) get table definition, 2) get DB schema and tables list, 3) execute SQL query. To make the best use of the agent, use a model designed for code-generation like codestral. Also make sure to describe what sort of info your tables contain in the system prompt.

## 6. PDF_agent.json

This is a Q&A agent designed to answer questions about PDF-files you've uploaded via the File_upload workflow. 

## 7. Abstract_search_agent.json

This is a workflow which uses PubMed's [Entrez API](https://www.ncbi.nlm.nih.gov/books/NBK25501/) to search for research papers that are relevant to the input question. It will return the top 3 papers based on the search result and summarise them into a unified output.