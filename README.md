# Serratus for Virus Discovery
This repository contains a collection of scripts for the RNA virus mining via Serratus. It identifies novel viruses and extracts metadata from the Sequence Read Archive (SRA). The project is organized into several scripts, each serving a specific purpose. Below is an overview of each script and its functionality.

## Configuration File (config.sh)

The configuration file contains essential project-specific parameters, such as project directories, file paths, and tool locations. It ensures the correct setup and execution of the scripts. If you are following this workflow, please modify the config.sh script. Users will need to set specific paths for certain tools and/or databases.

    Usage: Update the parameters in config.sh to match your project requirements.

## Script 1: Virus Data Retrieval (00.Ref_VirusFetch.sh)

This script retrieves nucleotide sequences for two virus families, Peribunyaviride and Phenuiviridae, from the NCBI GenBank database. It then extracts protein sequences, performs a sequence search using palmscan, and stores the results.

    Usage: ./00_Ref_VirusFetch.sh

## Script 2: Serratus sOTU Identification (01.Serratus.sh)

This script utilizes the usearch tool to identify sequence variants (sOTUs) for the previously fetched virus protein sequences. It filters the results based on alignment length and identity, extracts sOTUs, and checks their accessions against a source information file.

    Usage: ./Serratus.sh

## Script 3: Cross-Reference with SRA (02.cross_reference.sh)

This script cross-references the identified sOTUs with the Sequence Read Archive (SRA) using a Python script (sql_query_serratus.py). It extracts relevant information, such as SRA accessions, for further analysis.

    Usage: ./cross_reference.sh

## Script 4: Fetch SRA Metadata (03.metadata.sh)

This script fetches metadata for the identified SRA accessions, focusing on run IDs and coverage. It utilizes the pysradb tool to query the SRA database and saves the metadata in a structured format for downstream analysis.

    Usage: ./metadata.sh

## Script 5: Centroid Approach (04.Centroid_Approach.sh)

This script implements a centroid approach to identify novel sOTUs from Serratus and relies on Serratus RdRp assigned taxonomy. This script uses the custom Python script (sql_query_serratus.py) to extract and cross-reference relevant information such as taxonomy, palmprint sequence and associated SRA accession for the sOTUs of interest.

    Usage: ./scripts/04.Centroid_Approach.sh


## Packages and tools used in this project: 
* edirect
* palmscan
* USEARCH
* Diamond
* python v 3.9.15
    * pysradb
    * psycopg2
    * argparse
    * pandas

Feel free to explore each script for more details on their functionalities and adjust the configuration file according to your project specifications. If you encounter any issues or have questions, please raise an issue on the project page. 

