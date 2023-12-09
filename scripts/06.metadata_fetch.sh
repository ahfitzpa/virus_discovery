#!/bin/bash
#SBATCH --job-name=06.metadata
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-56:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/06.metadata_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/06.metadata_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from a separate file
source "config.sh"

# Set the path to the SRA Run IDs folder
sra_folder="$PROJECT_BASE_PATH/data/sra_sotu_centroid"

# Set the path to the metadata destination folder
metadata_folder="$PROJECT_BASE_PATH/data/SRA_metadata"

# Function to log errors
log_error() {
    local error_message="$1"
    echo "ERROR: $error_message" >&2
}

# Loop through each CSV file in the SRA Run IDs folder
for csv_file in "$sra_folder"/*.csv; do
    # Extract virus family name from the CSV file name
    virus_family=$(basename "$csv_file" | cut -d'_' -f1)

    # Create a new directory for each virus family under the metadata folder
    virus_folder="$metadata_folder/$virus_family"
    mkdir -p "$virus_folder"

    # Fetch metadata for each SRA Run ID and save it in individual files
    while IFS=, read -r run_id _; do
        if [ -n "$run_id" ]; then
            # Fetch metadata using efetch and save it to an XML file
            efetch -db sra -id "$run_id" -format summary > "$virus_folder/$run_id.xml"

            # Check the exit status of the efetch command
            if [ $? -ne 0 ]; then
                log_error "Failed to fetch metadata for $run_id"
                continue  # Skip to the next iteration if there's an error
            fi
        fi
    done < "$csv_file"
done

# Merge outputs for each virus family
for family_folder in "$metadata_folder"/*; do
    family=$(basename "$family_folder")
    merged_file="$metadata_folder/${family}_merged.xml"

    # Combine files within each virus family
    cat "$family_folder"/*.xml > "$merged_file"

    # Print status message
    echo "Merged metadata for $family saved to: $merged_file"
done
