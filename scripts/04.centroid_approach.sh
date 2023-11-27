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
cd $my_dir/$project_dir/scripts

# Load the required Python module
module load python/3.9.15

# Define the output directory for the joined tables
output="$my_dir/$project_dir/references/serratus"
# Create the directory if it doesn't exist
mkdir -p $output 

# Execute the SQL query to join tables palm_sra2 and palmdb2
python sql_query_serratus.py -q "SELECT
                                    ps.run_id,
                                    ps.coverage,
                                    ps.q_strand,
                                    ps.percent_identity,
                                    ps.evalue,
                                    ps.qc_pass,
                                    ps.q_sequence,
                                    pd.palm_id,
                                    pd.sotu,
                                    pd.percent_identity AS pd_percent_identity,
                                    pd.centroid,
                                    pd.palmprint,
                                    pg.gb_acc,
                                    pg.tax_id
                                  FROM palm_sra2 ps
                                  JOIN palmdb2 pd ON ps.palm_id = pd.palm_id
                                  JOIN palm_gb pg ON pd.palm_id = pg.palm_id;" -o "$output/palm_tax_gb.tsv"

# Define the output directory for the filtered data
output_sotu="$my_dir/$project_dir/data/sOTUs_centroid"
# Create the directory if it doesn't exist
mkdir -p $output_sotu

## Search for Peribunyaviridae viruses present in Serratus
python sql_query_serratus.py -q "SELECT * FROM palm_tax WHERE tax_family = 'Peribunyaviridae' AND centroid = 'true' ORDER BY tax_species DESC" -o $output_sotu/peribunyaviridae.tsv  || { echo "Error in SQL query"; exit 1; }

## Search for Phenuiviridae viruses present in Serratus
python sql_query_serratus.py -q "SELECT * FROM palm_tax WHERE tax_family = 'Phenuiviridae' AND centroid = 'true' ORDER BY tax_species DESC" -o $output_sotu/phenuiviridae.tsv  || { echo "Error in SQL query"; exit 1; }

# Execute SQL query to extract palmprint and palm_id for entries in palmdb2
python sql_query_serratus.py -q "SELECT pd.palm_id, pd.palmprint FROM palmdb2 pd JOIN $output_sotu/peribunyaviridae.tsv p ON pd.palm_id = p.palm_id;" -o $output_sotu/input_peribunyaviridae_fasta.tsv
python sql_query_serratus.py -q "SELECT pd.palm_id, pd.palmprint FROM palmdb2 pd JOIN $output_sotu/phenuiviridae.tsv p ON pd.palm_id = p.palm_id;" -o $output_sotu/input_phenuiviridae_fasta.tsv

# Convert outputs to fasta files
python $convert_fasta $output_sotu/input_peribunyaviridae_fasta.tsv $output_sotu/centroid_peribunyaviridae.fasta
python $convert_fasta $output_sotu/input_phenuiviridae_fasta.tsv $output_sotu/centroid_phenuiviridae.fasta

# Global align each Peribunyaviridae and Phenuiviridae sOTU to all sotus in serratus to define a "local"
usearch -usearch_global $sOTU -db $output_sotu/centroid_peribunyaviridae.fasta -id 0.45 \
  -blast6out  $output_sotu/peribunyavirida_palm.b6 -alnout  $output_sotu/peribunyavirida_palm.aln -fastapairs  $output_sotu/peribunyavirida_palm.pairfa.fasta

usearch -usearch_global $sOTU -db $output_sotu/centroid_phenuiviridae.fasta -id 0.45 \
  -blast6out  $output_sotu/phenuiviridae_palm.b6 -alnout  $output_sotu/phenuiviridae_palm.aln -fastapairs  $output_sotu/phenuiviridae_palm.pairfa.fa

# Extract sOTUs with percent identity not equal to 100% from peribunyaviridae
awk '$3 != 100' $output_sotu/peribunyavirida_palm.b6 > $output_sotu/non_100_peribunyavirida_palm.b6

# Extract sOTUs with percent identity not equal to 100% from phenuiviridae
awk '$3 != 100' $output_sotu/phenuiviridae_palm.b6 > $output_sotu/non_100_phenuiviridae_palm.b6

# Select sOTUs left in palm_tax with non-100% identity in peribunyaviridae
awk '$3 != 100' $output_sotu/non_100_peribunyaviridae_palm.b6 | cut -f1 | xargs -I {} python sql_query_serratus.py -q "SELECT * FROM palm_tax WHERE palm_id = '{}' AND centroid = 'true' AND gb_acc IS NULL AND tax_family = 'Peribunyaviridae' ORDER BY sotu DESC" -o $output_sotu/unique_peribunyaviridae_palm_tax.tsv

# Select sOTUs left in palm_tax with non-100% identity in phenuiviridae
awk '$3 != 100' $output_sotu/non_100_phenuiviridae_palm.b6 | cut -f1 | xargs -I {} python sql_query_serratus.py -q "SELECT * FROM palm_tax WHERE palm_id = '{}' AND centroid = 'true' AND gb_acc IS NULL AND tax_family = 'Phenuiviridae' ORDER BY sotu DESC" -o $output_sotu/unique_phenuiviridae_palm_tax.tsv

# Count unique sOTUs in peribunyaviridae_palm_tax.tsv
num_unique_peribunyaviridae=$(awk '!seen[$2]++' $output_sotu/unique_peribunyaviridae_palm_tax.tsv | wc -l)
echo "Number of unique sOTUs in peribunyaviridae_palm_tax.tsv: $num_unique_peribunyaviridae"

# Count unique sOTUs in phenuiviridae_palm_tax.tsv
num_unique_phenuiviridae=$(awk '!seen[$2]++' $output_sotu/unique_phenuiviridae_palm_tax.tsv | wc -l)
echo "Number of unique sOTUs in phenuiviridae_palm_tax.tsv: $num_unique_phenuiviridae"
