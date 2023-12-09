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
            # Fetch metadata using efetch and save it to a file
            efetch -db sra -id "$run_id" > "$virus_folder/$run_id.txt"

            # Remove the header line from each metadata file
            sed -i '1d' "$virus_folder/$run_id.txt"

            # Process the metadata file (example: print the first few lines)
            echo "Processing metadata for $run_id:"
            head "$virus_folder/$run_id.txt"
        fi
    done < "$csv_file"

    # Combine files within each virus folder (excluding headers)
    tail -n +2 "$virus_folder"/*.txt > "$virus_folder/combined_metadata.txt"
done
