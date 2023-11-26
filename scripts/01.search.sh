#!/bin/bash
#SBATCH --job-name=Serratus
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie
#SBATCH -t 0-6:00
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/Serratus_err_%j.log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/Serratus_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from a separate file
source "config.sh"

# Set other paths based on the configuration
outdir="$my_dir/$project_dir/data/sOTUs_Serratus"
protein_output_peribunyaviride="$my_dir/$project_dir/references/peribunyaviride/RdRp_pp_peribunyaviride.fa"
protein_output_phenuiviridae="$my_dir/$project_dir/references/phenuiviridae/dRp_pp_phenuiviridae.fa"
identity_threshold=0.45
source_info="/path/to/your/source_info.txt"

# Function to filter results based on alignment length and identity
filter_results() {
    local query_name="$1"
    local input_b6="$2"
    local output_b6_filtered="$3"

    awk -v query_name="$query_name" '$3 < 80 && $4 > 90' "$input_b6" > "$output_b6_filtered"
}

# Function to check accessions in source_info and output to a separate file
check_accessions() {
    local accession_list="$1"
    local source_info_file="$2"
    local output_file="$3"

    grep -wf "$accession_list" "$source_info_file" > "$output_file"
}

# Function to run usearch for a given query
run_usearch() {
    local query="$1"
    local query_name="$2"
    
    usearch -usearch_global "$sOTU" --db "$query" -id $identity_threshold --blast6out "$outdir/${query_name}_palmdb.b6" --alnout "$outdir/${query_name}_palmdb.aln" --fastapairs "$outdir/${query_name}_palmdb.pairfa.fa"
}

# Create the output directory if it doesn't exist
mkdir -p "$outdir"

# Run usearch for Peribunyaviride
run_usearch "$protein_output_peribunyaviride" "peribunyaviride"

# Filter results for Peribunyaviride
filter_results "peribunyaviride" "$outdir/peribunyaviride_palmdb.b6" "$outdir/peribunyaviride_palmdb_filtered.b6"

# Extract sOTUs for Peribunyaviride
grep ">" "$outdir/peribunyaviride_palmdb.pairfa.fa" | cut -d ' ' -f 1 | sed 's/>//' > "$outdir/peribunyaviride-like.sotu.list"

# Check accessions in source_info for Peribunyaviride
check_accessions "$outdir/peribunyaviride-like.sotu.list" "$source_info" "$outdir/peribunyaviride_source_info_filtered.tsv"

# Run usearch for Phenuiviridae
run_usearch "$protein_output_phenuiviridae" "phenuiviridae"

# Filter results for Phenuiviridae
filter_results "phenuiviridae" "$outdir/phenuiviridae_palmdb.b6" "$outdir/phenuiviridae_palmdb_filtered.b6"

# Extract sOTUs for Phenuiviridae
grep ">" "$outdir/phenuiviridae_palmdb.pairfa.fa" | cut -d ' ' -f 1 | sed 's/>//' > "$outdir/phenuiviridae-like.sotu.list"

# Check accessions in source_info for Phenuiviridae
check_accessions "$outdir/phenuiviridae-like.sotu.list" "$source_info" "$outdir/phenuiviridae_source_info_filtered.tsv"
