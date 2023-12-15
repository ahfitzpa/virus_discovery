#!/bin/bash
#SBATCH --job-name=00_Ref_VirusFetch # Job name
#SBATCH --mail-type END,FAIL
#SBATCH --mail-user amy.fitzpatrick@ucd.ie # Where to send mail
#SBATCH -t 0-4:00  # Time for the task to complete
#SBATCH --error=/home/people/fitzpatria/scratch/Serratus/logs/00VirusFetch_err_%j.log # Standard error log
#SBATCH --output=/home/people/fitzpatria/scratch/Serratus/logs/00VirusFetch_%j.log
#SBATCH --cpus-per-task=5

# Load configuration from config.sh
source config.sh

# Move to the Serratus directory
cd "$my_dir/$project_dir" || exit

# Create directories if they don't exist
mkdir -p references/peribunyaviride references/phenuiviridae raw_data

# Define the search terms for nucleotide sequences
peribunyaviride_query="txid1980416[Organism] AND refseq[Filter]"
phenuiviridae_query="txid1980418[Organism] AND refseq[Filter]"

# Download Peribunyaviride genomes
esearch -db nucleotide -query "$peribunyaviride_query" | efetch -format fasta > references/peribunyaviride/refseq_peribunyaviride.fasta

# Download phenuiviridae genomes
esearch -db nucleotide -query "$phenuiviridae_query" | efetch -format fasta > references/phenuiviridae/refseq_phenuiviridae.fasta

# Extract accession numbers for Peribunyaviride and phenuiviridae separately
grep '^>' references/peribunyaviride/refseq_peribunyaviride.fasta | cut -d' ' -f1 | cut -c2- > raw_data/accession_numbers_peribunyaviride.txt
grep '^>' references/phenuiviridae/refseq_phenuiviridae.fasta | cut -d' ' -f1 | cut -c2- > raw_data/accession_numbers_phenuiviridae.txt

# Your list of GenBank accession numbers
accession_numbers_peribunyaviride=$(cat raw_data/accession_numbers_peribunyaviride.txt)
accession_numbers_phenuiviridae=$(cat raw_data/accession_numbers_phenuiviridae.txt)

outdir="references"
output_file_peribunyaviride="$outdir/peribunyaviride/protein_sequences_peribunyaviride.fasta"
output_file_phenuiviridae="$outdir/phenuiviridae/protein_sequences_phenuiviridae.fasta"

fetch_genbank_protein_sequence() {
    accession="$1"
    response=$(efetch -db nuccore -id "$accession" -format fasta_cds_aa -mode text 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Error fetching protein sequence for accession: $accession"
    else
        echo "$response"
    fi
}

# Fetch protein sequences for Peribunyaviride
for accession in $accession_numbers_peribunyaviride; do
    echo "Fetching protein sequence for Peribunyaviride accession: $accession"
    fetch_genbank_protein_sequence "$accession" >> "$output_file_peribunyaviride"
done

# Fetch protein sequences for phenuiviridae
for accession in $accession_numbers_phenuiviridae; do
    echo "Fetching protein sequence for phenuiviridae accession: $accession"
    fetch_genbank_protein_sequence "$accession" >> "$output_file_phenuiviridae"
done

echo "Protein sequences for Peribunyaviride have been fetched and stored in $output_file_peribunyaviride."
echo "Protein sequences for phenuiviridae have been fetched and stored in $output_file_phenuiviridae."

# Run palmscan for Peribunyaviride
palmscan2 -search_pp "$output_file_peribunyaviride" -hiconf -rdrp -ppout "$outdir/peribunyaviride/RdRp_pp_peribunyaviride.fa" -report "$outdir/peribunyaviride/RdRp_pp_peribunyaviride.txt" -fevout "$outdir/peribunyaviride/RdRp_pp_peribunyaviride.fev"

# Run palmscan for Phenuiviridae
palmscan2 -search_pp "$output_file_phenuiviridae" -hiconf -rdrp -ppout "$outdir/phenuiviridae/dRp_pp_phenuiviridae.fa" -report "$outdir/phenuiviridae/RdRp_pp_phenuiviridae.txt" -fevout "$outdir/phenuiviridae/pRdRp_pp_phenuiviridae.fev"
