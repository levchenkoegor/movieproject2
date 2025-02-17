import numpy as np
import pandas as pd
from pathlib import Path

# Define paths
base_dir = Path('/data/elevchenko/MovieProject2')
task_name = 'backtothefuture'
output_per_subject_csv = base_dir / "bids_data/derivatives/group_analysis/backtothefuture" / f"{task_name}_per_subject_motion.csv"
output_mean_csv = base_dir / "bids_data/derivatives/group_analysis/backtothefuture" / f"{task_name}_mean_motion.csv"

# Define columns for output DataFrame
columns = ["Subject", "Task", "Run",
           "Mean Roll", "Mean Pitch", "Mean Yaw", "Mean dS", "Mean dL", "Mean dP",
           "Median Roll", "Median Pitch", "Median Yaw", "Median dS", "Median dL", "Median dP",
           "Max Roll", "Max Pitch", "Max Yaw", "Max dS", "Max dL", "Max dP"]
motion_stats = pd.DataFrame(columns=columns)

# Exclude subjects 24 and 36
excluded_subjects = {"sub-24", "sub-36"}

# Ensure we only process "sub-*" folders (avoid group_analysis, etc.)
subject_list = sorted([
    sub_dir.name for sub_dir in (base_dir / "bids_data/derivatives").iterdir()
    if sub_dir.is_dir() and sub_dir.name.startswith("sub-") and sub_dir.name not in excluded_subjects
])


# Function to load motion parameters for a subject and run
def load_motion_params(subject_id, run_number):
    subject_dir = base_dir / "bids_data/derivatives" / subject_id / task_name
    results_pattern = f"{subject_id}.results.*"

    # Find the latest results folder
    results_dirs = sorted(subject_dir.glob(results_pattern), reverse=True)
    if not results_dirs:
        print(f"No results directory found for {subject_id}. Expected pattern: {results_pattern}")
        return None

    latest_results_dir = results_dirs[0]  # Use the most recent results folder
    motion_file = latest_results_dir / f"dfile.r0{run_number}.1D"  # File for run 1, 2, or 3

    if not motion_file.exists():
        print(f"Motion file not found for {subject_id}, Run {run_number}: {motion_file}")
        return None

    return np.loadtxt(motion_file)


# Process each subject and extract motion statistics
for subject_id in subject_list:
    for run_number in range(1, 4):  # Loop through Run 1, Run 2, Run 3
        motion_data = load_motion_params(subject_id, run_number)

        if motion_data is None:
            continue  # Skip missing data

        # Ensure correct number of motion parameters (6 columns)
        if motion_data.shape[1] != 6:
            print(f"Skipping {subject_id}, Run {run_number}: unexpected column count ({motion_data.shape[1]})")
            continue

        # Compute statistics and round to 2 decimal places
        mean_vals = np.round(np.mean(motion_data, axis=0), 2)
        median_vals = np.round(np.median(motion_data, axis=0), 2)
        max_vals = np.round(np.max(motion_data, axis=0), 2)

        # Append results to DataFrame
        motion_stats = pd.concat([motion_stats, pd.DataFrame([{
            "Subject": subject_id, "Task": task_name, "Run": f"Run {run_number}",
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
