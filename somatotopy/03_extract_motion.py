import numpy as np
import pandas as pd
from pathlib import Path

# Define paths
base_dir = Path('/egor2/egor/MovieProject2')
task_name = 'somatotopy'
output_per_subject_csv = base_dir / "bids_data/derivatives/group_analysis/somatotopy" / f"{task_name}_per_subject_motion.csv"
output_mean_csv = base_dir / "bids_data/derivatives/group_analysis/somatotopy" / f"{task_name}_mean_motion.csv"
sequence_file = base_dir / "analysis/somatotopy/somatotopy_runssequence.csv"

# Define TR lengths
TR_lengths = {"Run 1": 459, "Run 2": 461}

# Load run sequence mapping
run_sequence_df = pd.read_csv(sequence_file)
run_sequence_df.set_index("subj id", inplace=True)  # Set subject ID as index for fast lookup

# Define columns for output DataFrame
columns = ["Subject", "Task", "Run",
           "Mean Roll", "Mean Pitch", "Mean Yaw", "Mean dS", "Mean dL", "Mean dP",
           "Median Roll", "Median Pitch", "Median Yaw", "Median dS", "Median dL", "Median dP",
           "Max Roll", "Max Pitch", "Max Yaw", "Max dS", "Max dL", "Max dP"]
motion_stats = pd.DataFrame(columns=columns)

# Exclude subjects
excluded_subjects = {}

# Ensure we only process "sub-*" folders (avoid group_analysis, etc.)
subject_list = sorted([
    sub_dir.name for sub_dir in (base_dir / "bids_data/derivatives").iterdir()
    if sub_dir.is_dir() and sub_dir.name.startswith("sub-") and sub_dir.name not in excluded_subjects
])

# Function to load and slice motion parameters for a subject
def load_and_slice_motion_params(subject_id):
    subject_dir = base_dir / "bids_data/derivatives" / subject_id / task_name
    results_pattern = f"{subject_id}.results.*"

    # Find the latest results folder
    results_dirs = sorted(subject_dir.glob(results_pattern), reverse=True)
    if not results_dirs:
        print(f"No results directory found for {subject_id}. Expected pattern: {results_pattern}")
        return None

    latest_results_dir = results_dirs[0]  # Use the most recent results folder
    motion_file = latest_results_dir / "dfile_rall.1D"  # The concatenated motion file

    if not motion_file.exists():
        print(f"Motion file not found for {subject_id}: {motion_file}")
        return None

    # Load the full concatenated motion file
    motion_data = np.loadtxt(motion_file)

    # Ensure correct number of motion parameters (6 columns)
    if motion_data.shape[1] != 6:
        print(f"Skipping {subject_id}: unexpected column count ({motion_data.shape[1]})")
        return None

    # Retrieve subject's run order
    if subject_id not in run_sequence_df.index:
        print(f"Skipping {subject_id}: No run sequence found.")
        return None

    run_order = run_sequence_df.loc[subject_id, "runs sequence"]
    if isinstance(run_order, str):
        run_order = run_order.split(", ")  # Convert "Run 1, Run 2" to a list

    if set(run_order) != {"Run 1", "Run 2"}:
        print(f"Skipping {subject_id}: Invalid run sequence format.")
        return None

    # Slice data based on subject-specific run order
    first_run, second_run = run_order
    first_run_length = TR_lengths[first_run]
    second_run_length = TR_lengths[second_run]

    if len(motion_data) < (first_run_length + second_run_length):
        print(f"Skipping {subject_id}: insufficient TRs ({len(motion_data)}). Expected at least {first_run_length + second_run_length}.")
        return None

    runs_data = {
        first_run: motion_data[:first_run_length],
        second_run: motion_data[first_run_length:first_run_length + second_run_length]
    }

    return runs_data

# Process each subject and extract motion statistics
for subject_id in subject_list:
    runs_data = load_and_slice_motion_params(subject_id)

    if runs_data is None:
        continue  # Skip missing or incomplete data

    for run_name, motion_data in runs_data.items():
        # Compute statistics and round to 2 decimal places
        mean_vals = np.round(np.mean(motion_data, axis=0), 2)
        median_vals = np.round(np.median(motion_data, axis=0), 2)
        max_vals = np.round(np.max(motion_data, axis=0), 2)

        # Append results to DataFrame
        motion_stats = pd.concat([motion_stats, pd.DataFrame([{
            "Subject": subject_id, "Task": task_name, "Run": run_name,
            "Mean Roll": mean_vals[0], "Mean Pitch": mean_vals[1], "Mean Yaw": mean_vals[2],
            "Mean dS": mean_vals[3], "Mean dL": mean_vals[4], "Mean dP": mean_vals[5],
            "Median Roll": median_vals[0], "Median Pitch": median_vals[1], "Median Yaw": median_vals[2],
            "Median dS": median_vals[3], "Median dL": median_vals[4], "Median dP": median_vals[5],
            "Max Roll": max_vals[0], "Max Pitch": max_vals[1], "Max Yaw": max_vals[2],
            "Max dS": max_vals[3], "Max dL": max_vals[4], "Max dP": max_vals[5]
        }])], ignore_index=True)

# Save per-subject motion statistics
motion_stats.to_csv(output_per_subject_csv, index=False)
print(f"Per-subject motion statistics saved to: {output_per_subject_csv}")

# Compute mean across all subjects
mean_motion_stats = motion_stats.drop(columns=["Subject"]).groupby(["Task", "Run"]).mean().reset_index().round(2)

# Save the mean motion statistics
mean_motion_stats.to_csv(output_mean_csv, index=False)
print(f"Mean motion statistics across subjects saved to: {output_mean_csv}")
