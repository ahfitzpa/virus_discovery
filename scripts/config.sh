#!/bin/bash

# Set project directories and paths
my_dir="/home/people/fitzpatria/scratch"
project_dir="Serratus"
sOTU="/home/people/fitzpatria/databases/palmdb-main/2021-03-14/uniques.fa"
source_info="$my_dir/$project_dir/source_info.txt"
pysradb_dir="/home/people/fitzpatria/tools/pysradb"
convert_fasta="scratch/Serratus/scripts/convert_tsv_to_fasta.py"

# Ensure project directory structure
project_structure=("data" "logs" "plots" "raw_data" "references" "results" "scripts")

# Create project directory if it doesn't exist
if [ ! -d "$my_dir/$project_dir" ]; then
    mkdir -p "$my_dir/$project_dir"
fi

# Move to the project directory
cd "$my_dir/$project_dir" || exit

# Create subdirectories if they don't exist
for subdir in "${project_structure[@]}"; do
    if [ ! -d "$subdir" ]; then
        mkdir -p "$subdir"
    fi
done

# Print message indicating successful setup
echo "Project directory structure is set up in $my_dir/$project_dir."
