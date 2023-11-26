with open('sql_palmdb.tsv', 'r') as tsv_file, open('output.fasta', 'w') as fasta_file:
    # Skip header
    next(tsv_file)
    
    for line in tsv_file:
        # Split the line into fields
        fields = line.strip().split(',')
        
        # Write FASTA header
        fasta_file.write('>' + fields[0] + '\n')
        
        # Write the sequence (last column) to the FASTA file
        fasta_file.write(fields[5] + '\n')
