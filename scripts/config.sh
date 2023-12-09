#!/bin/bash

# Set project directories and paths
PROJECT_BASE_PATH="/home/people/fitzpatria/scratch/Serratus"
sOTU="/home/people/fitzpatria/databases/palmdb-main/2021-03-14/uniques.fa"
SOURCE_INFO_FILE="$PROJECT_BASE_PATH/source_info.txt"
PYSRADB_DIR="/home/people/fitzpatria/tools/pysradb"
CONVERT_FASTA_SCRIPT="$PROJECT_BASE_PATH/scripts/convert_csv_to_fasta.py"
SQL_SERRATUS_SCRIPT="$PROJECT_BASE_PATH/scripts/sql_query_serratus.py"

# Ensure project directory structure
PROJECT_STRUCTURE=("data" "logs" "plots" "raw_data" "references" "results" "scripts")

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_BASE_PATH" ]; then
    mkdir -p "$PROJECT_BASE_PATH"
fi

# Move to the project directory
cd "$PROJECT_BASE_PATH" || exit

# Create subdirectories if they don't exist
for subdir in "${PROJECT_STRUCTURE[@]}"; do
    if [ ! -d "$subdir" ]; then
        mkdir -p "$subdir"
    fi
done

# Print message indicating successful setup
echo "Project directory structure is set up in $PROJECT_BASE_PATH."
