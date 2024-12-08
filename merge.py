import pandas as pd
import os
import glob
from datetime import datetime

def read_csv(csv_file):
    encodings = ['utf-8', 'latin-1', 'iso-8859-1', 'cp1252']
    for encoding in encodings:
        try:
            df = pd.read_csv(
                csv_file,
                encoding=encoding,
                low_memory=False,
                dtype=str
            )
            if not df.empty:
                return df
        except:
            continue
    return pd.DataFrame()

def merge_csvs_to_excel(csv_files, output_file):
    with pd.ExcelWriter(output_file) as writer:
        for csv_file in csv_files:
            df = read_csv(csv_file)
            if df.empty:
                print(f"Skipping empty file: {csv_file}")
                continue
            sheet_name = os.path.splitext(os.path.basename(csv_file))[0][:31]
            df.to_excel(writer, sheet_name=sheet_name, index=False)

# Get the output file path from environment variable or command line argument
output_file = os.environ.get('OUTPUT_FILE')

if not output_file:
    current_date = datetime.now().strftime('%Y/%m/%d')
    output_file = os.path.join('/home/amitdemo/inventory', current_date, 'output.xlsx')

# Ensure the directory exists
os.makedirs(os.path.dirname(output_file), exist_ok=True)

# Find CSV files in the same directory as the output file
csv_dir = os.path.dirname(output_file)
csv_files = glob.glob(os.path.join(csv_dir, '*.csv'))

print(f"Output file: {output_file}")
print(f"CSV directory: {csv_dir}")
print(f"CSV files found: {csv_files}")

if csv_files:
    merge_csvs_to_excel(csv_files, output_file)
    print(f"Successfully merged {len(csv_files)} CSV files to {output_file}")
else:
    print("No CSV files found in the directory")
    # Exit with a non-zero status to indicate failure
    import sys
    sys.exit(1)