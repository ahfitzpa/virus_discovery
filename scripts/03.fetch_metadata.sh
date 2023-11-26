#!/bin/bash
#SBATCH --job-name=metadata
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-6:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/metadata_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/metadata_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from a separate file
source "config.sh"

# Activate conda environment
echo "Activating conda environment..."
module load anaconda/3.2022.10
source activate "$pysradb_dir"

sOTU_dir="$my_dir/$project_dir/data/SRA_palm_id"

# Define input files
phenuiviridae_file="$sOTU_dir/phenuiviridae_sra_accessions.txt"
peribunyaviride_file="$sOTU_dir/peribunyaviride_sra_accessions.txt"

# Create output directory
metadata_dir="$my_dir/$project_dir/data/SRA_metadata"
mkdir -p "$metadata_dir" || { echo "Error: Unable to create output directory $metadata_dir"; exit 1; }

# Log script start
echo "Script started at: $(date)"

# Function to fetch metadata
fetch_metadata() {
    local virus_file="$1"
    local virus_name="$2"

    # Extract run_id and coverage for each virus
    echo "Extracting run_id and coverage from $virus_file..."
    
    # Create a text file to store filtered SRA run IDs
    filtered_run_ids_file="$metadata_dir/${virus_name}_filtered_run_ids.txt"
    touch "$filtered_run_ids_file" || { echo "Error: Unable to create filtered run IDs file for $virus_name"; exit 1; }
    
    awk -F',' 'NR > 1 && $4 > 2 {print $2}' "$virus_file" > "$filtered_run_ids_file" || { echo "Error: Unable to filter run IDs for $virus_name"; exit 1; }
    
    # Fetch metadata for each run_id
    echo "Fetching metadata for $virus_name..."
    cat "$filtered_run_ids_file" | while read -r run_id; do
        echo "Processing SRA run number: $run_id"
        metadata=$(pysradb metadata "$run_id" --detailed | tail -n +2)
        if [ -z "$metadata" ]; then
            echo "Warning: No metadata found for SRA run number $run_id"
        else
            echo -e "$run_id\t$metadata" >> "$metadata_dir/${virus_name}_metadata.tsv" || { echo "Error: Unable to write metadata for $run_id"; exit 1; }
            echo "Processed SRA run number: $run_id"
        fi
    done
}

# Fetch metadata for phenuiviridae
fetch_metadata "$phenuiviridae_file" "phenuiviridae"

# Fetch metadata for peribunyaviride
fetch_metadata "$peribunyaviride_file" "peribunyaviride"

# Log script end
echo "Script completed at: $(date)"

# Deactivate conda environment
echo "Deactivating conda environment..."
conda deactivate 
module unload anaconda/3.2022.10