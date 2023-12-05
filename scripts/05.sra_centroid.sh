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

# Function to process virus
process_virus() {
    local family_name="$1"
    local unique_csv="$2"  # Path to the unique CSV file

    if [ -f "$unique_csv" ]; then
        # Extract sOTUs from column 1 of the unique CSV file
        echo "Extracting sOTUs from $unique_csv..."
        local virus_sotus
        if virus_sotus=$(cut -d',' -f1 "$unique_csv"); then
            echo "Done."
        else
            echo "Error extracting sOTUs from $unique_csv. Check logs for details."
            return
        fi

        # Display unique sOTUs for debugging
        echo "Unique sOTUs for $family_name: $virus_sotus"

        if [ -z "$virus_sotus" ]; then
            echo "Error: No sOTUs found in $unique_csv. Skipping family $family_name."
            log_error "$family_name" "$unique_csv" "Empty input file"
            return
        fi

        # Add single quotes around each value in the IN clause using awk
        local quoted_sotus
        # Add single quotes around each value in the IN clause using awk
        quoted_sotus=$(echo "$virus_sotus" | awk -v ORS="," '{print "\x27" $1 "\x27"}' | sed 's/,$//')


        # Create a temporary SQL file
        local sql_file="$output_dir/fetch_sra_info.sql"
        cat >"$sql_file" <<EOF
\COPY (SELECT * FROM palm_sra WHERE palm_id IN ($quoted_sotus)) TO '$output_dir/${family_name}_sra_accessions.csv' WITH CSV HEADER
EOF

        # Print the SQL command for debugging
        echo "SQL Command:"
        cat "$sql_file"

        # Fetch sra information from palm_sra
        if psql -h "$host" -d "$database" -U "$user" -f "$sql_file"; then
            echo "Successfully fetched SRA information for $family_name from palm_sra."
            # Log the number of rows written to the output file
            log_success "$family_name" "$output_dir/${family_name}_sra_accessions.csv"
        else
            echo "Error: Failed to fetch SRA information for $family_name from palm_sra."
            log_error "$family_name" "$output_dir/${family_name}_sra_accessions.csv" "Query error details"
        fi

        # Remove the temporary SQL file
        rm "$sql_file"
    else
        echo "Error: Could not find unique CSV file for family $family_name."
        log_error "$family_name" "$unique_csv" "Missing CSV file"
    fi
}

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
    echo "Successfully fetched $num_rows rows of SRA information for $family_name from palm_sra."
    # Check if the file is empty
    if [ "$num_rows" -eq 1 ]; then
        echo "Warning: Output file is empty for $family_name."
    fi
}

# List of unique CSV files
unique_csv_files=(
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Togaviridae/unique_togaviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Caliciviridae/unique_caliciviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Flaviviridae/unique_flaviviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Peribunyaviridae/unique_peribunyaviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Hepeviridae/unique_hepeviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Hantaviridae/unique_hantaviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Astroviridae/unique_astroviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Sedoreoviridae/unique_sedoreoviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Rhabdoviridae/unique_rhabdoviridae.csv"
    "/scratch/fitzpatria/Serratus/data/sOTUs_centroid/Phenuiviridae/unique_phenuiviridae.csv"
)

# Iterate over each unique CSV file
for unique_csv_file in "${unique_csv_files[@]}"; do
    family_name=$(basename "$(dirname "$unique_csv_file")")
    process_virus "$family_name" "$unique_csv_file"
done

echo "Script completed at: $(date)"
