#!/bin/bash
#SBATCH --job-name=centroid_approach
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-10:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/centroid_approach_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/centroid_approach_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from the specified file. Ensure you have modified for your system
source config.sh

# Move to the script directory
cd "$my_dir/$project_dir/scripts"

# Define the output directory for the joined tables
output="$my_dir/$project_dir/references/serratus"
# Create the directory if it doesn't exist
mkdir -p "$output"

# Define the path for the output file
palm_tax_output="$output/palm_tax.csv"

# Database connection details
host="serratus-aurora-20210406.cluster-ro-ccz9y6yshbls.us-east-1.rds.amazonaws.com"
database="summary"
user="public_reader"
export PGPASSWORD="serratus"

# Function to process each virus family
process_family() {
    local family="$1"
    
    # Define the output directory for the filtered data
    output_sotu="$my_dir/$project_dir/data/sOTUs_centroid/$family"
    # Create the directory if it doesn't exist
    mkdir -p "$output_sotu"

    # Use variables consistently
    palm_tax="$palm_tax_output"
    family_output="$output_sotu/${family,,}.csv"

    # Search for the specific virus family present in Serratus
    if ! awk -F',' -v family="$family" '$13==family && $4=="t" {print}' "$palm_tax" | sort -t',' -k7,7 -r > "$family_output"; then
        echo "Error: Failed to search for $family viruses in Serratus."
        exit 1
    fi

    ####################################################################################################################################################################
    # Fetch additional information from palmdb2 based on palm IDs for the specific virus family
    input_fasta="$output_sotu/input_${family,,}_fasta.csv"
    palm_ids=$(awk -F',' -v family="$family" '$13==family && $4=="t" {print $1}' "$palm_tax" | awk 'NF {print $0}' | sed "s/.*/'&'/; H; \$!d; x; s/\n/,/g")
    if [ -z "$palm_ids" ]; then
        echo "No valid palm IDs for $family found."
        exit 1
    fi

    # Remove leading comma if present
    palm_ids=${palm_ids#,}

    if ! psql -h "$host" -d "$database" -U "$user" -c "\COPY (SELECT palm_id, palmprint FROM palmdb2 WHERE palm_id IN ($palm_ids)) TO '$input_fasta' WITH CSV HEADER"; then
        echo "Error: Failed to fetch additional information for $family from palmdb2."
        exit 1
    fi

    # Convert output to a fasta file
    python $convert_fasta "$input_fasta" "$output_sotu/centroid_${family,,}.fasta"
    ###################################################################################################################################################################
    # Global align each virus family sOTU to all sotus in serratus to define a "local"
    if ! usearch -usearch_global "$sOTU" -db "$output_sotu/centroid_${family,,}.fasta" -id 0.45 \
      -blast6out  "$output_sotu/${family,,}_palm.b6" -alnout  "$output_sotu/${family,,}_palm.aln" -fastapairs  "$output_sotu/${family,,}_palm.pairfa.fasta"; then
        echo "Error: Failed to perform global alignment for $family."
        exit 1
    fi

    ####################################################################################################################################################################
    # Extract sOTUs with percent identity not equal to 100%
    if ! awk -F',' '$6 != 100' "$family_output" > "$output_sotu/non_100_${family,,}.csv"; then
        echo "Error: Failed to extract sOTUs with non-100% identity from $family."
        exit 1
    fi

    ####################################################################################################################################################################
    # Fetch additional information from palm_tax based on palm IDs
    palm_ids=$(awk -F',' '$6 != 100 && $1 != "" {print $1}' "$output_sotu/non_100_${family,,}.csv" | awk 'NF {print $0}' | sed "s/.*/'&'/; H; \$!d; x; s/\n/,/g")
    if [ -z "$palm_ids" ]; then
        echo "No valid palm IDs for $family found."
        exit 1
    fi

    # Remove leading comma if present
    palm_ids=${palm_ids#,}

    if ! psql -h "$host" -d "$database" -U "$user" -c "\COPY (
        SELECT * FROM palm_tax
        WHERE
            palm_id IN ($palm_ids)
            AND centroid='t'
        ORDER BY sotu DESC
    ) TO '$output_sotu/unique_${family,,}.csv' WITH CSV HEADER"; then
        echo "Error: Failed to fetch additional information for $family from palm_tax."
        exit 1
    fi

    ####################################################################################################################################################################
    # Count unique sOTUs
    unique_count=$(awk -F',' -v family="$family" '$13==family && $6 != 100' "$output_sotu/unique_${family,,}.csv" | cut -d',' -f1 | sort -u | wc -l)

    echo "Number of unique sOTUs in $family: $unique_count"
}

# List of virus families
families="Phenuiviridae Rhabdoviridae Sedoreoviridae Peribunyaviridae Flaviviridae Togaviridae Astroviridae Caliciviridae Hepeviridae Hantaviridae"

# Iterate over each family
for family in $families; do
    process_family "$family"
done
