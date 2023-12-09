#!/bin/bash
#SBATCH --job-name=metadata_filter
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-48:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/filter_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/filter_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from a separate file
source "config.sh"

# Set the base path
BASE_PATH="$PROJECT_BASE_PATH/data/SRA_metadata"

# Define keywords for filtering
FILTER_KEYWORDS=("virus" "viral" "viruses" "viral metagenome" "virome")

# Create a subdirectory to store filtered metadata
FILTERED_DIR="$PROJECT_BASE_PATH/data/SRA_filtered_metadata"
mkdir -p "$FILTERED_DIR"

# Loop through each metadata file
for metadata_file in "$BASE_PATH"/*.tsv; do
    # Extract file name without extension
    filename=$(basename -- "$metadata_file")
    filename_no_ext="${filename%.*}"

    # Convert filename to lowercase
    filename_lower=$(echo "$filename_no_ext" | tr '[:upper:]' '[:lower:]')

    # Create a filtered file in the subdirectory with the correct naming pattern
    filtered_file="$FILTERED_DIR/${filename_lower}_filtered.tsv"

    # Apply filtering criteria using awk to check for keywords in all columns (case-insensitive)
    awk -F'\t' -v OFS='\t' '{
        found_keyword = 0;
        for (i = 1; i <= NF; i++) {
            if(tolower($i) ~ /virus|viruses|viral metagenome|virome/) {
                found_keyword = 1;
                break;
            }
        }
        if (!found_keyword) {
            print;
        }
    }' "$metadata_file" > "$filtered_file"

    # Print status message
    echo "Filtered metadata saved to: $filtered_file"
done

# Copy CSV files into the filtered metadata directory, convert to TSV, and then merge
cd "$PROJECT_BASE_PATH/data/sra_sotu_centroid"

# Loop through each CSV file
for csv_file in *.csv; do
    # Extract file name without extension and convert to lowercase
    csv_filename_lower=$(echo "${csv_file%.*}" | sed 's/_sra_accessions//I' | tr '[:upper:]' '[:lower:]')

    # Copy CSV file to filtered metadata directory
    cp "$csv_file" "$FILTERED_DIR/"

    # Convert CSV to TSV using sed
    sed 's/,/\t/g' "$FILTERED_DIR/$csv_file" > "$FILTERED_DIR/${csv_filename_lower}.tsv"

    # Corrected naming pattern for the filtered TSV files
    filtered_file="$FILTERED_DIR/${csv_filename_lower}_metadata_filtered.tsv"
    echo "Processing files: $filtered_file and ${csv_filename_lower}.tsv"

    # Debug statement: print the first few lines of each file
    echo "First few lines of $filtered_file:"
    head "$filtered_file"
    echo "First few lines of ${csv_filename_lower}.tsv:"
    head "$FILTERED_DIR/${csv_filename_lower}.tsv"

    # Sort the metadata and converted TSV files based on the first column
    sort -k1,1 "$filtered_file" -o "$filtered_file"
    sort -k1,1 "$FILTERED_DIR/${csv_filename_lower}.tsv" -o "$FILTERED_DIR/${csv_filename_lower}.tsv"
  
    # Merge corresponding converted TSV and filtered TSV files using awk
    awk 'BEGIN {FS=OFS="\t"} NR==FNR{a[$1]=$3 FS $4; next} {print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, a[$1]}' "$FILTERED_DIR/${csv_filename_lower}.tsv" "$filtered_file" > "$FILTERED_DIR/${csv_filename_lower}_merged.tsv"

    # Print the first few lines of the merged file for debugging
    echo "First few lines of merged file:"
    head "$FILTERED_DIR/${csv_filename_lower}_merged.tsv"

    # Add headers to the merged TSV file
    echo -e "run_accession\tstudy_accession\tstudy_title\texperiment_accession\tinstrument\tinstrument_model\tlibrary_size\tlibrary_strategy\tlibrary_source\tlibrary_selection\tpalm_id\tsotu" > "$FILTERED_DIR/${csv_filename_lower}_merged_with_headers.tsv"
    cat "$FILTERED_DIR/${csv_filename_lower}_merged.tsv" >> "$FILTERED_DIR/${csv_filename_lower}_merged_with_headers.tsv"

    # Print the first few lines of the merged file with headers for debugging
    echo "First few lines of merged file with headers:"
    head "$FILTERED_DIR/${csv_filename_lower}_merged_with_headers.tsv"

    # Remove the original CSV and intermediate TSV files
    rm "$FILTERED_DIR/$csv_file"
    rm "$FILTERED_DIR/${csv_filename_lower}.tsv"
    rm "$FILTERED_DIR/${csv_filename_lower}_merged.tsv"
done

# Remove the error log output files
rm -f "$FILTERED_DIR"/*_filter_error.log

# Remove non-merged files and intermediate TSV files
cd "$FILTERED_DIR"
for filtered_tsv in *_metadata_filtered.tsv; do
    # Extract file name without extension
    filtered_filename_no_ext="${filtered_tsv%.*}"

    # Check if corresponding merged file exists
    merged_file="${filtered_filename_no_ext}_merged_with_headers.tsv"
    if [ -e "$merged_file" ]; then
        echo "Merged file exists for: $filtered_tsv"
    else
        # Remove non-merged and intermediate TSV files
        echo "Removing non-merged and intermediate files: $filtered_tsv"
        rm -f "$filtered_tsv" "$FILTERED_DIR/${filtered_filename_no_ext}.tsv" "$FILTERED_DIR/${filtered_filename_no_ext}_merged.tsv"
    fi
done

# Rename the final output files to family name .tsv
for merged_with_headers in *_merged_with_headers.tsv; do
    family_name="${merged_with_headers%_merged_with_headers.tsv}"
    mv "$merged_with_headers" "$family_name.tsv"
done

echo "Non-merged and intermediate files removed. Final output files renamed."

# Remove non-merged files
cd "$FILTERED_DIR"

# Loop through each filtered TSV file
for filtered_tsv in *_metadata_filtered.tsv; do
    # Extract file name without extension
    filtered_filename_no_ext="${filtered_tsv%.*}"

    # Check if corresponding merged file exists
    merged_file="${filtered_filename_no_ext}_merged.tsv"
    if [ -e "$merged_file" ]; then
        echo "Merged file exists for: $filtered_tsv"
    else
        # Remove non-merged file
        echo "Removing non-merged file: $filtered_tsv"
        rm -f "$filtered_tsv"
    fi
done

# Remove rows with no entry for palm_id or sotu in all filtered files
cd "$FILTERED_DIR"

# Check if there are any files matching the pattern
if ls *_metadata_filtered.tsv 1> /dev/null 2>&1; then
  for filtered_file in *_metadata_filtered.tsv; do
      # Remove rows with no entry for palm_id or sotu
      awk -F'\t' -v OFS='\t' '$11 != "" && $12 != ""' "$filtered_file" > "${filtered_file%.tsv}_final.tsv"

      # Replace the original filtered file with the one containing only valid rows
      mv "${filtered_file%.tsv}_final.tsv" "$filtered_file"
  done

  echo "Rows with no entry for palm_id or sotu removed from all filtered files."
else
  echo "No files matching the pattern *_metadata_filtered.tsv found in the directory."
fi
