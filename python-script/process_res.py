import pandas as pd
import numpy as np
import re
from typing import List, Dict, Tuple
import os
import sys
from io import StringIO
import argparse


def parse_oryza_res_file(file_path):
    """
    Parse ORYZA res.dat file and convert it to CSV format

    Parameters:
    file_path (str): Path to the res.dat file

    Returns:
    pandas.DataFrame: Combined data from all rerun sets
    """

    with open(file_path, 'r') as file:
        content = file.read()

    # Split content by rerun sets
    rerun_sections = re.split(r'\* OUTPUT FROM RERUN SET:\s+(\d+)', content)

    all_data = []

    # Process each rerun set (skip the first empty section)
    for i in range(1, len(rerun_sections), 2):
        rerun_number = int(rerun_sections[i])
        section_content = rerun_sections[i + 1]

        # Find the data table section
        lines = section_content.split('\n')

        # Look for the header line with column names
        header_line_idx = None
        data_start_idx = None

        for idx, line in enumerate(lines):
            if 'TIME' in line and 'IR' in line:  # Header line
                header_line_idx = idx
                data_start_idx = idx + 2  # Skip the empty line after header
                break

        if header_line_idx is None:
            continue

        # Extract column headers
        header_line = lines[header_line_idx]
        columns = header_line.split('\t')
        columns = [col.strip() for col in columns if col.strip()]

        # Extract data rows
        data_rows = []
        for line in lines[data_start_idx:]:
            line = line.strip()
            if not line or line.startswith('*') or line.startswith('OUTPUT FROM RERUN SET'):
                break

            # Split by tab and clean values
            values = line.split('\t')
            values = [val.strip() for val in values if val.strip()]

            if len(values) == len(columns):
                # Convert scientific notation and clean data
                cleaned_values = []
                for val in values:
                    try:
                        # Handle scientific notation
                        if 'E' in val or 'e' in val:
                            cleaned_values.append(float(val))
                        else:
                            cleaned_values.append(float(val))
                    except ValueError:
                        cleaned_values.append(val)

                data_rows.append(cleaned_values)

        # Create DataFrame for this rerun set
        if data_rows:
            df_rerun = pd.DataFrame(data_rows, columns=columns)
            df_rerun['RERUN_SET'] = rerun_number
            all_data.append(df_rerun)

    # Combine all rerun sets
    if all_data:
        final_df = pd.concat(all_data, ignore_index=True)
        # Reorder columns to put RERUN_SET first
        cols = ['RERUN_SET'] + [col for col in final_df.columns if col != 'RERUN_SET']
        final_df = final_df[cols]
        return final_df
    else:
        return pd.DataFrame()

def convert_res_to_csv(input_file, output_file=None):
    """
    Convert ORYZA res.dat file to CSV

    Parameters:
    input_file (str): Path to input res.dat file
    output_file (str): Path to output CSV file (optional)

    Returns:
    pandas.DataFrame: Converted data
    """

    # Parse the file
    df = parse_oryza_res_file(input_file)

    if df.empty:
        print("No data found in the file")
        return df

    # Save to CSV if output file specified
    if output_file:
        df.to_csv(output_file, index=False)
        print(f"Data successfully converted and saved to {output_file}")

    print(f"Converted data shape: {df.shape}")
    print(f"Columns: {list(df.columns)}")
    print(f"Rerun sets found: {sorted(df['RERUN_SET'].unique())}")

    return df

def main():
    """Main function for command line usage"""
    parser = argparse.ArgumentParser(description='Convert ORYZA res.dat file to CSV')
    parser.add_argument('input_file', help='Path to input res.dat file')
    parser.add_argument('output_file', help='Path to output CSV file')
    
    args = parser.parse_args()
    
    # Convert the file
    df = convert_res_to_csv(args.input_file, args.output_file)
    
    return df

if __name__ == "__main__":
    if len(sys.argv) == 3:
        # Command line arguments provided
        main()
    else:
        # Default behavior for testing
        df1 = convert_res_to_csv('C:\\Users\\pc\\Gama_Workspace\\Field Experiment\\includes\\Results\\CF_s3\\cf_res.dat', 'C:\\Users\\pc\\Gama_Workspace\\Field Experiment\\includes\\Results\\CF_s3\\cf_res.csv')
