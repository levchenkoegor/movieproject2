import pandas as pd
import numpy as np
from pathlib import Path

# Define root path (update 'root_path' with your base directory)
root_path = Path(r'/data/elevchenko/MovieProject2/')
output_path = Path(root_path / 'bids_data/derivatives')

# Create output directory if it does not exist
output_path.mkdir(parents=True, exist_ok=True)

# Initialize an empty list to hold data for all subjects
all_data = []

# Iterate over each subject's folder
for subject_path in sorted((root_path/'raw_data').glob('sub-*')):
    subject_id = subject_path.stem  # Get subject ID (e.g., 'sub-22')

    # Find all CSV files with 'pRF' in the filename
    for csv_file in sorted(subject_path.rglob('*pRF*.csv')):

        # skip the run where participant didn't understand the task
        if any(substring in str(csv_file) for substring in ['29-Jul-2024_19_24_15',
                                                     '28-Aug-2024_18_39_04']):
            continue

        # Extract run number from filename (assuming format includes 'run-1', 'run-2', etc.)
        if 'run-' in csv_file.stem:
            # Handle 'run-' case: run number follows 'run-'
            run_number = int(csv_file.stem.split('run-')[1][0])
        else:
            # Handle 'pRF' case: second element after 'pRF' indicates run number
            filename_parts = csv_file.stem.split('_')
            pRF_index = filename_parts.index('pRF')
            run_number = int(filename_parts[pRF_index + 1])  # Get the second part after 'pRF'

        # Load the CSV file
        df = pd.read_csv(csv_file)

        # Extract 'hit_rate' and 'fa_rate' columns
        hit_rate = df['hits'].iloc[0]
        fa_rate = df['false_alarms'].iloc[0]

        # Append the data to the list
        all_data.append({
            'subject_id': subject_id,
            'run': run_number,
            'hit_rate': hit_rate,
            'fa_rate': fa_rate
        })

        # Print results for the current subject and run
        print(f"Subject ID: {subject_id}, Run: {run_number}, Hit Rate: {hit_rate}, FA Rate: {fa_rate}")

# Convert the list of dictionaries to a DataFrame
all_data_df = pd.DataFrame(all_data).round(2)

# Save to CSV
output_file = output_path / 'retinotopy_accuracy_all.csv'
all_data_df.to_csv(output_file, index=False)

print(f'Data saved to {output_file}')
