#!/bin/bash

# Source .bash_profile to ensure environment variables are available
source "$HOME/.bash_profile"

# Set project directories and paths
PROJECT_BASE_PATH="/home/people/fitzpatria/scratch/Serratus"
REFERENCES_DIR="$PROJECT_BASE_PATH/references"
SOURCE_INFO_FILE="$PROJECT_BASE_PATH/source_info.txt"
PYSRADB_DIR="/home/people/fitzpatria/tools/pysradb"
CONVERT_FASTA_SCRIPT="$PROJECT_BASE_PATH/scripts/convert_csv_to_fasta.py"
SQL_SERRATUS_SCRIPT="$PROJECT_BASE_PATH/scripts/sql_query_serratus.py"
GITHUB_REPO="https://github.com/rcedgar/palmdb.git"
BRANCH_NAME="main"

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

# List of required tools
REQUIRED_TOOLS=("palmscan2" "efetch" "usearch" "python3" "psql")

check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo >&2 "$1 is not installed. Please install it and re-run the script."
        exit 1
    fi
}

# Check for required tools
for tool in "${REQUIRED_TOOLS[@]}"; do
    check_tool "$tool"
done

# Check for Conda environment "hostile"
if ! conda activate hostile &> /dev/null; then
    echo >&2 "Conda environment 'hostile' is not activated. Please activate it and re-run the script."
    exit 1
fi

# Print message indicating successful setup
echo "Tool requirements have been checked."

# Download sOTU database using git clone
if [ ! -d "$REFERENCES_DIR/2021-03-14" ]; then
    echo "Downloading sOTU database using git clone..."
    git clone "$GITHUB_REPO" --branch "$BRANCH_NAME" "$REFERENCES_DIR/palmdb"
    echo "sOTU database downloaded to $REFERENCES_DIR."
else
    echo "sOTU database already exists in $REFERENCES_DIR. Skipping download."
fi
