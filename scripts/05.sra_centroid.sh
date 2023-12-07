#!/bin/bash
#SBATCH --job-name=sra_cross_reference
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-6:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/sra_cross_reference_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/sra_cross_reference_%j.log
#SBATCH --cpus-per-task=10

# Database connection details
host="serratus-aurora-20210406.cluster-ro-ccz9y6yshbls.us-east-1.rds.amazonaws.com"
database="summary"
user="public_reader"
export PGPASSWORD="serratus"

# Load configuration from a separate file
source "config.sh"

# Create output directory
output_dir="$my_dir/$project_dir/data/sra_sotu_centroid"
mkdir -p "$output_dir"

# Log script start
echo "Script started at: $(date)"

# Function to log errors
log_error() {
    local family_name="$1"
    local file_path="$2"
    local error_message="$3"
    echo "Error: $error_message" >> "$output_dir/error.log"
    echo "Family: $family_name" >> "$output_dir/error.log"
    echo "Unique CSV file: $file_path" >> "$output_dir/error.log"
}

# Function to log success
log_success() {
    local family_name="$1"
    local output_file="$2"
    # Log the number of rows written to the output file
    local num_rows
    num_rows=$(wc -l "$output_file" | cut -d ' ' -f 1)
    echo "Successfully fetched $num_rows rows of SRA information for $family_name from palm_virome."
    # Check if the file is empty
    if [ "$num_rows" -eq 1 ]; then
        echo "Warning: Output file is empty for $family_name."
    fi
}

# List of unique CSV files
unique_csv_files=(
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Togaviridae/unique_togaviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Caliciviridae/unique_caliciviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Flaviviridae/unique_flaviviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Peribunyaviridae/unique_peribunyaviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Hepeviridae/unique_hepeviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Hantaviridae/unique_hantaviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Astroviridae/unique_astroviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Sedoreoviridae/unique_sedoreoviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Rhabdoviridae/unique_rhabdoviridae.csv"
    "/home/people/fitzpatria/scratch/Serratus/data/sOTUs_centroid/Phenuiviridae/unique_phenuiviridae.csv"
)

# Iterate over each unique CSV file
for unique_csv_file in "${unique_csv_files[@]}"; do
    family_name=$(basename "$(dirname "$unique_csv_file")")

    # Extract sOTUs from column 1 of the unique CSV file, filtering out empty lines
    echo "Processing family: $family_name"
    palm_ids=($(awk -F',' 'NR>1 && $1 != "" {printf "\x27%s\x27,", $1}' "$unique_csv_file" | sed 's/,$//'))

    if [ ${#palm_ids[@]} -eq 0 ]; then
        echo "Error: No non-empty sOTUs found in $unique_csv_file. Skipping family $family_name."
        log_error "$family_name" "$unique_csv_file" "Empty or invalid sOTUs"
        continue
    fi

    # Construct the COPY command
    copy_command="COPY (SELECT run, bio_sample, palm_id, sotu FROM palm_virome WHERE sotu IN (${palm_ids[*]})) TO STDOUT WITH CSV HEADER"

    # Debugging: Log the COPY command
    echo "COPY Command: $copy_command" >> "$output_dir/debug.log"

    # Execute the COPY command using psql
    if psql -h "$host" -d "$database" -U "$user" -c "$copy_command" > "$output_dir/${family_name}_sra_accessions.csv"; then
        # Debugging: Log the output of the SQL command
        echo "Successfully fetched SRA information for $family_name from palm_virome."
        # Log the number of rows written to the output file
        log_success "$family_name" "$output_dir/${family_name}_sra_accessions.csv"

        # Count the number of unique palm_ids in the output file
        unique_palm_ids=$(awk -F',' 'NR>1 {print $3}' "$output_dir/${family_name}_sra_accessions.csv" | sort -u | wc -l)
        echo "Number of unique palm_ids in ${family_name}_sra_accessions.csv: $unique_palm_ids"
    else
        echo "Error: Failed to fetch SRA information for $family_name from palm_virome."
        log_error "$family_name" "$output_dir/${family_name}_sra_accessions.csv" "Query error details"
    fi
done

echo "Script completed at: $(date)"
