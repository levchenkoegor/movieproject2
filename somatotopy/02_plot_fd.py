import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

from pathlib import Path


# Define paths
base_dir = Path('/data/elevchenko/MovieProject2')
somatotopy_dir = 'somatotopy'
fd_file_pattern = 'motion_{subject_id}_enorm.1D'

plots_dir = base_dir / "bids_data/derivatives/group_analysis"
plots_dir.mkdir(parents=True, exist_ok=True)

# Find subjects with somatotopy data
subject_list = sorted([sub_dir.name for sub_dir in (base_dir / "bids_data/derivatives").iterdir() if (sub_dir / somatotopy_dir).exists()])

# Remove "sub-" prefix for subject IDs
def strip_sub_prefix(subject_id):
    return subject_id.replace("sub-", "")

# Define timing files
timing_files = {
    "Left face": base_dir / 'stimuli' / "task-somatotopy_condition-leftface_run-both.1D",
    "Left foot": base_dir / 'stimuli' / "task-somatotopy_condition-leftfoot_run-both.1D",
    "Left hand": base_dir / 'stimuli' / "task-somatotopy_condition-lefthand_run-both.1D",
    "Left tongue": base_dir / 'stimuli' / "task-somatotopy_condition-lefttongue_run-both.1D",
    "Rest": base_dir / 'stimuli' / "task-somatotopy_condition-rest_run-both.1D",
    "Right face": base_dir / 'stimuli' / "task-somatotopy_condition-rightface_run-both.1D",
    "Right foot": base_dir / 'stimuli' / "task-somatotopy_condition-rightfoot_run-both.1D",
    "Right hand": base_dir / 'stimuli' / "task-somatotopy_condition-righthand_run-both.1D",
    "Right tongue": base_dir / 'stimuli' / "task-somatotopy_condition-righttongue_run-both.1D"
}

# Load the runs sequence
run_sequence = pd.read_csv(base_dir / 'analysis' / 'somatotopy'/ 'somatotopy_runssequence.csv', delimiter=',')
run_sequence = run_sequence.dropna(subset=['runs sequence'])  # Remove rows with empty "runs sequence"

# Function to parse timing information
def parse_afni_timing(file_path):
    with file_path.open("r") as f:
        lines = f.readlines()
    timing_info = []
    for line in lines:
        trials = line.strip().split()
        for trial in trials:
            onset, duration = trial.split(":")
            timing_info.append((int(onset), int(duration)))
    return timing_info

# Adjust timing for concatenated runs
def adjust_global_timing(subject_id, timing, run_sequence_df):
    subject_row = run_sequence_df.loc[run_sequence_df['subj id'] == subject_id]
    if subject_row.empty:
        raise ValueError(f"Run sequence not found for subject: {subject_id}")

    run_order = subject_row.iloc[0]['runs sequence'].split(", ")  # Assuming "Run 1, Run 2" or "Run 2, Run 1"
    half_length = len(timing) // 2  # Half of the timing list corresponds to one run

    if run_order == ["Run 1", "Run 2"]:
        # Global timing for Run 1
        run1_timing = timing[:half_length]
        run1_total_duration = sum(onset + duration for onset, duration in run1_timing)

        # Adjust Run 2 timing
        run2_timing = [(onset + run1_total_duration, duration) for onset, duration in timing[half_length:]]
        global_timing = run1_timing + run2_timing

    elif run_order == ["Run 2", "Run 1"]:
        # Global timing for Run 2
        run2_timing = timing[:half_length]
        run2_total_duration = sum(onset + duration for onset, duration in run2_timing)

        # Adjust Run 1 timing
        run1_timing = [(onset + run2_total_duration, duration) for onset, duration in timing[half_length:]]
        global_timing = run2_timing + run1_timing

    else:
        raise ValueError(f"Unexpected run order for subject: {subject_id}")

    return global_timing


# Timing information for tasks (parsed and adjusted for global timing)
task_timing_info = {}
for task, file_path in timing_files.items():
    local_timing = parse_afni_timing(file_path)
    task_timing_info[task] = {
        subject_id: adjust_global_timing(subject_id, local_timing, run_sequence)
        for subject_id in subject_list if subject_id in run_sequence['subj id'].values
    }

# Initialize variables
fd_all_subjects = []


# Function to load FD for a given subject
def load_fd(subject_id):
    subject_dir = base_dir / "bids_data/derivatives" / subject_id / somatotopy_dir
    results_pattern = f"{subject_id}.results.*"  # Match timestamped folder

    # Use glob to find results directories
    results_dirs = sorted(subject_dir.glob(results_pattern), reverse=True)  # Sort to get the latest

    if not results_dirs:
        print(f"No results directory found for {subject_id}. Expected pattern: {results_pattern}")
        return []

    latest_results_dir = results_dirs[0]  # Use the most recent results folder
    fd_filename = fd_file_pattern.format(subject_id=strip_sub_prefix(subject_id))
    fd_path = latest_results_dir / fd_filename  # Construct full FD file path

    if not fd_path.exists():
        print(f"FD file not found for {subject_id}: {fd_path}")
        return []

    return np.loadtxt(fd_path)


# Collect FD values for all subjects
for subject_id in subject_list:
    fd_values = load_fd(subject_id)
    if len(fd_values) > 0:
        fd_all_subjects.extend(fd_values)

# Plot overall FD distribution as percentages
plt.figure(figsize=(10, 6))
n, bins = np.histogram(fd_all_subjects, bins=100, range=(0, max(fd_all_subjects)), density=True)
bin_width = bins[1] - bins[0]
n_percent = n * bin_width * 100  # Convert to percentages by scaling with bin width

# Calculate the 95th percentile
fd_95th_percentile = np.percentile(fd_all_subjects, 95)

plt.bar(bins[:-1], n_percent, width=bin_width, color='skyblue', edgecolor='black')
# Add a dashed line for the 95th percentile
plt.axvline(fd_95th_percentile, color='red', linestyle='--', linewidth=1,
            label=f'95th Percentile: {fd_95th_percentile:.2f} mm')
plt.title("Framewise Displacement Distribution Across Participants")
plt.xlabel("Framewise Displacement (mm)")
plt.xlim(-0.05, 1.2)
plt.ylabel("Percentage (%)")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.legend(loc='upper right')
plt.savefig(plots_dir / "somatotopy" / "task-somatotopy_overall_fd_distribution_percentage.png")
plt.close()

# Task-based FD analysis
task_fd_list = []

for task, timings in task_timing_info.items():
    fd_task = []
    for subject_id, subject_timings in timings.items():
        fd_values = load_fd(subject_id)
        if len(fd_values) == 0:
            continue

        # Extract FD values for each timing (onset and duration)
        for onset, duration in subject_timings:
            fd_task.extend(fd_values[onset:onset + duration])

    task_fd_list.append(fd_task)


# Plot FD by task
plt.figure(figsize=(12, 8))
positions = np.arange(1, len(task_timing_info) + 1)

# Calculate max FD value across all tasks and add padding
max_fd_value = max(max(task) if len(task) > 0 else 0 for task in task_fd_list)
ylim_padding = 0.1 * max_fd_value

plt.violinplot(task_fd_list, positions, showextrema=False)
plt.boxplot(task_fd_list, widths=0.1, showfliers=False, patch_artist=True,
            boxprops={'color': 'blue', 'facecolor': 'lightgrey'},
            medianprops={'color': 'red'})

plt.xticks(positions, list(task_timing_info.keys()), rotation=45)
plt.ylim(-0.05, 0.8)  # Adjust ylim dynamically
plt.title("Condition-Specific Framewise Displacement")
plt.xlabel("Conditions")
plt.ylabel("Framewise Displacement (mm)")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(plots_dir / "somatotopy" / "task-somatotopy_condition_specific_fd.png")
plt.close()

print('Plots were saved')
