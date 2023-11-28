import csv
import sys

def csv_to_fasta(input_csv, output_fasta):
    try:
        with open(input_csv, 'r') as csv_file, open(output_fasta, 'w') as fasta_file:
            # Create a CSV reader with a comma as the delimiter
            csv_reader = csv.reader(csv_file, delimiter=',')
            
            # Skip header
            next(csv_reader)
            
            for row in csv_reader:
                # Write FASTA header
                fasta_file.write('>' + row[0] + '\n')
                
                # Write the sequence (last column) to the FASTA file
                fasta_file.write(row[1] + '\n')

        print(f"Fasta file '{output_fasta}' created successfully.")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    # Check if the correct number of command-line arguments is provided
    if len(sys.argv) != 3:
        print("Usage: python scriptname.py input_csv output_fasta")
        sys.exit(1)

    # Extract command-line arguments
    input_csv_file = sys.argv[1]
    output_fasta_file = sys.argv[2]

    # Call the function with user-provided file paths
    csv_to_fasta(input_csv_file, output_fasta_file)
