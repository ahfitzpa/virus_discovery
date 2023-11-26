#!/bin/bash
#SBATCH --job-name=cross_reference
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-2:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/cross_reference_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/cross_reference_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from a separate file
source "config.sh"

# Define input files
phenuiviridae_file="$my_dir/$project_dir/data/sOTUs_Serratus/phenuiviridae_palmdb_filtered.b6"
peribunyaviride_file="$my_dir/$project_dir/data/sOTUs_Serratus/peribunyaviride_palmdb_filtered.b6"

# Create output directory
output_dir="$my_dir/$project_dir/data/SRA_palm_id"
mkdir -p "$output_dir"

# Log script start
echo "Script started at: $(date)"

# Function to process virus
process_virus() {
    local virus_file="$1"
    local virus_name="$2"

    # Extract sOTUs from column 9 of virus file
    echo "Extracting sOTUs from $virus_file..."
    local virus_sotus=$(awk '{print $1}' "$virus_file")
    echo "Done."

    # Remove duplicates
    echo "Removing duplicate sOTUs..."
    local unique_sotus=$(echo "$virus_sotus" | sort -u)
    echo "Done."

    # Display unique sOTUs for debugging
    echo "Unique sOTUs for $virus_name: $unique_sotus"

    # Add single quotes around each value in the IN clause using awk
    # Add single quotes around each value in the IN clause using awk, and remove the extra quote at the end
    quoted_sotus=$(echo "$unique_sotus" | awk '{printf "'\''%s'\'',", $0}' | sed 's/,$//')

    # Select all columns for the matching palm_id
    python sql_query_serratus.py -q "SELECT * FROM palm_sra WHERE palm_id IN ($quoted_sotus)" -o "$output_dir/${virus_name}_sra_accessions.txt"

    if [ $? -eq 0 ]; then
        echo "Query for all sOTUs in $virus_name completed successfully."
    else
        echo "Error running query for all sOTUs in $virus_name. Check logs for details."
    fi
}

# Process phenuiviridae
process_virus "$phenuiviridae_file" "phenuiviridae"

# Process peribunyaviride
process_virus "$peribunyaviride_file" "peribunyaviride"

# Log script end
echo "Script completed at: $(date)"
