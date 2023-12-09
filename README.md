# Serratus for Virus Discovery
This repository contains a collection of scripts for the RNA virus mining via Serratus. It identifies novel viruses and extracts metadata from the Sequence Read Archive (SRA). The project is organized into several scripts, each serving a specific purpose. They have been written to run on a HPC RedHat Linux system without sudo rights. User installed tools are used, as well as global environment modules.  Below is an overview of each script and its functionality.

## Configuration File (config.sh)

The configuration file contains essential project-specific parameters, such as project directories, file paths, and tool locations. It ensures the correct setup and execution of the scripts. If you are following this workflow, please modify the config.sh script. Users will need to set specific paths for certain tools and/or databases.

## Script 1: Virus Data Retrieval (00.Ref_VirusFetch.sh)

This script retrieves nucleotide sequences for two virus families, Peribunyaviride and Phenuiviridae, from the NCBI GenBank database. It then extracts protein sequences, performs a sequence search using palmscan, and stores the results.

## Script 2: Serratus sOTU Identification (01.Serratus.sh)

This script utilizes the usearch tool to identify sequence variants (sOTUs) for the previously fetched virus protein sequences. It filters the results based on alignment length and identity, extracts sOTUs, and checks their accessions against a source information file.

## Script 3: Cross-Reference with SRA (02.cross_reference.sh)

This script cross-references the identified sOTUs with the Sequence Read Archive (SRA) using a Python script (sql_query_serratus.py). It extracts relevant information, such as SRA accessions, for further analysis.

## Script 4: Fetch SRA Metadata (03.metadata.sh)

This script fetches metadata for the identified SRA accessions, focusing on run IDs and coverage. It utilizes the pysradb tool to query the SRA database and saves the metadata in a structured format for downstream analysis.

## Script 5: Centroid Approach (04.Centroid_Approach.sh)

This script implements the centroid approach to identify novel sOTUs (sequence variants) from the Serratus database. The centroid approach involves the following steps:

1. **Database Setup:**
   - The script establishes a connection to the Serratus database, downloading essential information from the palmdb2 and palm_tax tables.

2. **SOTU Retrieval:**
   - It identifies specific virus families, such as Phenuiviridae, Rhabdoviridae, Sedoreoviridae, Peribunyaviridae, Flaviviridae, Togaviridae, Astroviridae, Caliciviridae, Hepeviridae, and Hantaviridae.

3. **Local Alignment:**
   - For each identified virus family, the script performs a global alignment of the family's sOTUs against all sOTUs present in the Serratus database. This alignment is crucial for defining a "local" alignment specific to the virus family.

4. **Identity Filtering:**
   - It extracts sOTUs with a percentage identity not equal to 100% and creates a CSV file with non-100% identity sOTUs for further analysis.

5. **Additional Information Retrieval:**
   - The script fetches additional information from the palmdb2 and palm_tax tables based on palm IDs, ensuring a comprehensive dataset for subsequent steps.

6. **Unique sOTUs Count:**
   - It counts the number of unique sOTUs for each virus family, excluding those with 100% identity, providing insights into the diversity within each family.

## Script 6: SRA Cross-Reference (05.sra_cross_reference.sh)

This script performs cross-referencing of Serratus sOTUs with the Sequence Read Archive (SRA) using information from unique CSV files. It extracts relevant SRA accessions for further analysis.

    Usage: ./scripts/05.sra_cross_reference.sh

## Script 7: Metadata Fetch (06.metadata_fetch.sh)

This script fetches metadata for identified SRA accessions, focusing on run IDs and coverage. It utilizes the pysradb tool to query the SRA database and saves the metadata in a structured format for downstream analysis.

## Packages and tools used in this project: 
* edirect
* psql
* palmscan
* USEARCH
* Diamond
* python v 3.9.15
    * pysradb
    * psycopg2
    * argparse
    * pandas

Feel free to explore each script for more details on their functionalities and adjust the configuration file according to your project specifications. If you encounter any issues or have questions, please raise an issue on the project page. 

