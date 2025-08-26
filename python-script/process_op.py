import pandas as pd
import numpy as np
import re
from typing import List, Dict, Tuple
import os
import sys
from io import StringIO
import argparse

def convert_opdat_to_csv(input_file, output_file):
    """
    Convert op.dat file to CSV format

    Args:
        input_file (str): Path to the input op.dat file
        output_file (str): Path to the output CSV file
    """
    try:
        # Read the file
        with open(input_file, 'r') as file:
            lines = file.readlines()

        # Extract header line (first line)
        header_line = lines[0].strip()

        # Split header by multiple spaces to get column names
        headers = re.split(r'\s+', header_line)

        # Extract data lines (skip first line which is header)
        data_lines = [line.strip() for line in lines[1:] if line.strip()]

        # Parse data rows
        data_rows = []
        for line in data_lines:
            # Split by multiple spaces
            values = re.split(r'\s+', line)
            data_rows.append(values)

        # Create DataFrame
        df = pd.DataFrame(data_rows, columns=headers)

        # Convert numeric columns to appropriate data types
        for col in df.columns:
            try:
                # Try to convert to numeric
                df[col] = pd.to_numeric(df[col])
            except ValueError:
                # Keep as string if conversion fails
                pass

        # Save to CSV
        df.to_csv(output_file, index=False)
        
        # Print results for GAMA to capture
        print(f"SUCCESS: Converted {input_file} to {output_file}")
        print(f"SHAPE: {df.shape[0]} rows, {df.shape[1]} columns")
        print(f"COLUMNS: {','.join(df.columns)}")
        
        return df
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        sys.exit(1)

def main():
    """Main function for command line usage"""
    parser = argparse.ArgumentParser(description='Convert ORYZA op.dat file to CSV')
    parser.add_argument('input_file', help='Path to input op.dat file')
    parser.add_argument('output_file', help='Path to output CSV file')
    
    args = parser.parse_args()
    
    # Convert the file
    df = convert_opdat_to_csv(args.input_file, args.output_file)
    
    return df

if __name__ == "__main__":
    # If called directly (e.g., from command line or GAMA)
    if len(sys.argv) == 3:
        # Command line arguments provided
        main()
    else:
        # Default behavior for testing
        df1 = convert_opdat_to_csv('C:\\Users\\pc\\Gama_Workspace\\Field Experiment\\includes\\Results\\CF_s3\\cf_op.dat', 'C:\\Users\\pc\\Gama_Workspace\\Field Experiment\\includes\\Results\\CF_s3\\cf_op.csv')