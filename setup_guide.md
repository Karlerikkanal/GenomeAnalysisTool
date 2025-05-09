# Setup guide

Below is a guide to set up all the components necessary to run this workflow.

## System/Hardware requirements

Make sure your computer/server can build and run the base version of Kraken 2, which requires around 100GB of space and 32GB of memory at the minimum. I would recommend at least 64GB of memory and 512GB storage plus enough space to store your genome files. Use Linux as the OS as I haven't tested it on a MacOS and can't guarantee that it works there.

### My setup
- **OS:** Ubuntu 24.04.2 on WSL
- **Processor:** 11th Gen Intel(R) Core(TM) i5-11400F @ 2.60GHz   2.59 GHz
- **Graphics card:** NVIDIA GeForce GTX 1650
- **RAM:** 128GB
- **Storage:** 2TB

## Installing the components

### Conda environment

First install [Anaconda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) on your system. Then install the environment by using the provided environment.yml file.
```bash 
conda env create -f environment.yaml
```
Then activate that environment `conda activate GenomeAnalysisTool`

**Note:** I couldn't get Roary to work in that environment, so instead download Roary via apt: `sudo apt-get install roary`

### Kraken

Clone these repositories in the directory you're gonna be operating this workflow from:

```
git clone https://github.com/DerrickWood/kraken2.git
git clone https://github.com/jenniferlu717/Bracken.git
git clone https://github.com/jenniferlu717/KrakenTools.git
```

Create a Kraken 2 database following their [guide](https://github.com/DerrickWood/kraken2/blob/master/docs/MANUAL.markdown). Then install Bracken (view the README at their repository page) and build the bracken database ontop of the Kraken 2 database you just built.

### n8n

I used npm to run n8n. To do this, first install [Node](https://nodejs.org/en/).

Then run `npm install n8n -g` to install it globally and then run `n8n` to start.

### Database setup and SQL commands

If you don't have a database set up yet, I recommend following [this great guide](https://www.youtube.com/watch?v=tducLYZzElo) by ProgrammingKnowledge to set up Postgres and pgAdmin. Feel free to use other interfaces like DBeaver as long as they connect to the databases on your system.

In pgAdmin, files for importing should be placed in /var/lib/pgadmin/storage/{your_email@email.com}

You should create 2 databases, one that hosts your main data, and another one which hosts vector data to chat with PDF files.

To create the vector database, you need the extension pgvector. Install it using, replacing 17 with your version of postgres: `sudo apt install postgresql-17-pgvector`

Then run this command in your vector database to enable it `# CREATE EXTENSION vector;`

Once your main database is created, run this create table query below to create the annotations table.

```
CREATE TABLE kegg_annotations (
    id                           INTEGER,
    "Strain number"              TEXT,
    locus_tag                    TEXT,
    ftype                        TEXT,
    length_bp                    INTEGER,
    gene                         TEXT,
    ec_number                    TEXT,
    cog                          TEXT,
    product                      TEXT,
    quantification_keggcharter   INTEGER,
    taxon                        TEXT,
    ko_ec_column                 TEXT,
    ec_ec_column                 TEXT,
    ko_cog_column                TEXT,
    ko_keggcharter               TEXT,
    ec_number_keggcharter        TEXT
);
```


## Setting up the workflows

1. Run `n8n` to start n8n.
2. Create a new workflow and import the workflows from file.
3. Set up your postgres and Mistral credentials.
4. Set your own folders to watch for input in the File Upload workflow. Specifically make sure the one uploading to postgres regular database matches the one in run_keggcharter.sh. By default, it's set to "$HOME/database_files/" in the run_keggcharter script. Note that n8n does not recognize $HOME as a variable, so you need to set the full path in n8n.
5. In the abstracts search agent there are three nodes that need the filepath to be changed. In both the read and write nodes, decide in which folders you want the json files to be created. Then in the "Extract abstracts from IDs" node change the respective input and output filepaths in the command to match the ones you just picked.
6. Update the system prompts for Master agent and Database agent to suit your own data.
7. Activate all of the workflows.

## Running the workflows

Once the workflows are activated, access their respective parameter forms and fill out the parameters. 

Master workflow form: http://localhost:5678/form/master-workflow

Kraken workflow form: http://localhost:5678/form/kraken-workflow 

Once you've submitted the respective forms, the pipeline will automatically run. If a result is unsatisfactory, remove the folder/subfolder of the result that is unsatisfactory and run the script from the command line again. The scripts are designed to skip already completed folders and they will always source the paramaters from the configuration file `config.sh`, unless specifically assigned from the command line.

**Important!!**

The workflows expect the input data for Trim Galore! to be in this format:
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

To chat with the database and papers, use the chat option in the Master agent window. For more detailed descriptions of workflows, view the README file in the workflows directory.