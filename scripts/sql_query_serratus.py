import argparse
import psycopg2
import pandas as pd

# Database connection details
HOST = "serratus-aurora-20210406.cluster-ro-ccz9y6yshbls.us-east-1.rds.amazonaws.com"
DATABASE = "summary"
USER = "public_reader"
PASSWORD = "serratus"

# Function to build and execute the query
def execute_query(conn, custom_query, output_file=None):
    df = pd.read_sql_query(custom_query, conn)

    print("Executing query:")
    print(custom_query)

    print("Head of the DataFrame:")
    print(df.head(5))  # Display the first five rows

    if output_file:
        df.to_csv(output_file, index=False)
        print(f"Query results saved to {output_file}")

def table_exists(conn, table_name):
    with conn.cursor() as cursor:
        cursor.execute(f"SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '{table_name}')")
        return cursor.fetchone()[0]

def get_columns_for_table(conn, table_name):
    with conn.cursor() as cursor:
        cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '{table_name}'")
        return [row[0] for row in cursor.fetchall()]

def get_filters(value_list, column_name):
    if value_list:
        # Convert values to a string representation, assuming they are strings or numbers
        values_str = ', '.join(map(str, value_list))
        return f"{column_name} IN ({values_str})"
    else:
        return None

def main():
    parser = argparse.ArgumentParser(description="Query Serratus database for specific filters and columns.")
    parser.add_argument("-t", "--table", help="Name of the table to investigate.")
    parser.add_argument("-c", "--columns", help="Comma-separated list of columns to investigate.")
    parser.add_argument("-q", "--query", help="Execute a custom SQL query.")
    parser.add_argument("-o", "--output", help="Output file path for the query results.")
    parser.add_argument("-vl", "--value_list", help="Comma-separated list of values for filtering.")

    args = parser.parse_args()

    print("Parsed arguments:")
    print(args)

    try:
        with psycopg2.connect(host=HOST, database=DATABASE, user=USER, password=PASSWORD) as conn:
            print("Successfully connected to Serratus 🗻")

            # If a custom query is specified, execute it directly
            if args.query:
                if args.table or args.columns:
                    raise ValueError("Table (-t) and columns (-c) should not be used with the query (-q) argument.")
                execute_query(conn, args.query, args.output)
                return

            # If the user specified a table, show its columns or list available tables
            if args.table:
                print("Inside table block")  # Add this line
                print(f"Table name from arguments: {args.table}")  # Add this line
                if args.table.lower() == 'list':
                    with conn.cursor() as cursor:
                        cursor.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'")
                        tables = [row[0] for row in cursor.fetchall()]
                        print(f"Available tables: {', '.join(tables)}")
                    return

                if args.table.lower().endswith('list'):
                    table_name = args.table.lower()[:-4]  # Remove ' list' from the end
                    print(f"Checking existence of table: {table_name}")  # Add this line
                    if not table_exists(conn, table_name):
                        raise ValueError(f"Table '{table_name}' does not exist in the database.")

                    columns = get_columns_for_table(conn, table_name)
                    if columns is not None:
                        print(f"Columns for table '{table_name}': {', '.join(columns)}")
                    return

                table_name = args.table
                print(f"Checking existence of table: {table_name}")  # Add this line
                if not table_exists(conn, table_name):
                    raise ValueError(f"Table '{table_name}' does not exist in the database.")

                columns = get_columns_for_table(conn, table_name)
                print(f"Columns for table '{table_name}': {', '.join(columns)}")

                # If the user specified columns, proceed with filters
                if args.columns:
                    print("Inside columns block")  # Add this line
                    filters = get_filters(args.value_list, args.columns)  # Pass column_name and value_list
                    columns = args.columns.split(',')
                    table_name = args.table

                    # Update the call to execute_query to include filters
                    execute_query(conn, f"SELECT {', '.join(columns)} FROM {table_name} WHERE {filters}", args.output)

    except psycopg2.Error as e:
        print(f"Error connecting to database: {e}")
    except ValueError as ve:
        print(f"Error: {ve}")

if __name__ == "__main__":
    main()
