import numpy as np
import matplotlib.pyplot as plt

from pathlib import Path

# Define paths
base_dir = Path('/data/elevchenko/MovieProject2')
retinotopy_dir = 'retinotopy'
fd_file_pattern = 'motion_{subject_id}_enorm.1D'

plots_dir = base_dir / "bids_data/derivatives/group_analysis"
plots_dir.mkdir(parents=True, exist_ok=True)

# Find subjects with retinotopy data
subject_list = sorted([sub_dir.name for sub_dir in (base_dir / "bids_data/derivatives").iterdir() if (sub_dir / retinotopy_dir).exists()])

# Remove "sub-" prefix for subject IDs
def strip_sub_prefix(subject_id):
    return subject_id.replace("sub-", "")

# Function to load FD for a given subject
def load_fd(subject_id):
    subject_dir = base_dir / "bids_data/derivatives" / subject_id / retinotopy_dir
    results_pattern = f"{subject_id}.results.*"  # Match timestamped folder

    # Use glob to find results directories
    results_dirs = sorted(subject_dir.glob(results_pattern), reverse=True)  # Sort to get the latest

    if not results_dirs:
        print(f"No results directory found for {subject_id}. Expected pattern: {results_pattern}")
        return None

    latest_results_dir = results_dirs[0]  # Use the most recent results folder
    fd_filename = fd_file_pattern.format(subject_id=strip_sub_prefix(subject_id))
    fd_path = latest_results_dir / fd_filename  # Construct full FD file path

    if not fd_path.exists():
        print(f"FD file not found for {subject_id}: {fd_path}")
        return None

    return np.loadtxt(fd_path)


# Initialize variables for runs
fd_runs = {"Run 1": [], "Run 2": [], "Run 3": []}
TRs_per_run = 348  # Fixed number of TRs per run

# Collect FD values for all subjects and split into runs
for subject_id in subject_list:
    fd_values = load_fd(subject_id)

    if fd_values is not None and len(fd_values) >= TRs_per_run * 3:  # Ensure we have at least 3 full runs
        fd_runs["Run 1"].extend(fd_values[:TRs_per_run])      # First 348 TRs
        fd_runs["Run 2"].extend(fd_values[TRs_per_run:TRs_per_run*2])  # Next 348 TRs
        fd_runs["Run 3"].extend(fd_values[TRs_per_run*2:TRs_per_run*3])  # Final 348 TRs
    else:
        print(f"Skipping {subject_id}, insufficient TRs: {len(fd_values) if fd_values is not None else 'None'}")


# Plot overall FD distribution as percentages
fd_all_subjects = np.concatenate(list(fd_runs.values())) if any(fd_runs.values()) else []

plt.figure(figsize=(10, 6))
if len(fd_all_subjects) > 0:
    n, bins = np.histogram(fd_all_subjects, bins=100, range=(0, max(fd_all_subjects)), density=True)
    bin_width = bins[1] - bins[0]
    n_percent = n * bin_width * 100  # Convert to percentages by scaling with bin width

    # Calculate the 95th percentile
    fd_95th_percentile = np.percentile(fd_all_subjects, 95)

    plt.bar(bins[:-1], n_percent, width=bin_width, color='skyblue', edgecolor='black')
    plt.axvline(fd_95th_percentile, color='red', linestyle='--', linewidth=1,
                label=f'95th Percentile: {fd_95th_percentile:.2f} mm')
    plt.title("Framewise Displacement Distribution Across Participants")
    plt.xlabel("Framewise Displacement (mm)")
    plt.xlim(-0.05, 1.2)
    plt.ylabel("Percentage (%)")
    plt.grid(axis='y', linestyle='--', alpha=0.7)
    plt.legend(loc='upper right')
    plt.savefig(plots_dir / "retinotopy" / "task-retinotopy_overall_fd_distribution_percentage.png")
    plt.close()
else:
    print("No FD values available for distribution plot.")

# **Violin Plot: FD for Each Run**
plt.figure(figsize=(12, 8))

positions = np.arange(1, 4)  # Positions for Run 1, Run 2, Run 3
run_labels = ["Run 1", "Run 2", "Run 3"]

plt.violinplot([fd_runs["Run 1"], fd_runs["Run 2"], fd_runs["Run 3"]], positions, showextrema=False)
plt.boxplot([fd_runs["Run 1"], fd_runs["Run 2"], fd_runs["Run 3"]], widths=0.1, showfliers=False, patch_artist=True,
            boxprops={'color': 'blue', 'facecolor': 'lightgrey'},
            medianprops={'color': 'red'})

plt.xticks(positions, run_labels)
plt.ylim(-0.05, 1.2)  # Adjust ylim dynamically
plt.title("Framewise Displacement by Run")
plt.xlabel("Runs")
plt.ylabel("Framewise Displacement (mm)")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(plots_dir / "retinotopy" / "task-retinotopy_fd_by_run.png")
plt.close()

print('Plots were saved')
