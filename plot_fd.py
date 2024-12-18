from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt

# Define paths
base_dir = Path("/data/elevchenko/MovieProject2")
somatotopy_dir = "somatotopy"
fd_file_pattern = "motion_sub-{subject_id}_enorm.1D"

plots_dir = base_dir / "bids_data/derivatives/plots"
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

# Timing information for tasks (parsed from files)
task_timing_info = {task: parse_afni_timing(file_path) for task, file_path in timing_files.items()}

# Initialize variables
fd_all_subjects = []

# Function to load FD for a given subject
def load_fd(subject_id):
    fd_path = base_dir / "bids_data/derivatives" / subject_id / somatotopy_dir / f"{subject_id}.results" / fd_file_pattern.format(subject_id=strip_sub_prefix(subject_id))
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
n, bins = np.histogram(fd_all_subjects, bins=50, range=(0, 1.2), density=True)
bin_width = bins[1] - bins[0]
n_percent = n * bin_width * 100  # Convert to percentages by scaling with bin width

plt.bar(bins[:-1], n_percent, width=bin_width, color='skyblue', edgecolor='black')
plt.title("Framewise Displacement Distribution Across Participants")
plt.xlabel("Framewise Displacement (mm)")
plt.ylabel("Percentage (%)")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.savefig(plots_dir / "overall_fd_distribution_percentage.png")
plt.close()


# Task-based FD analysis
task_fd_list = []

for task, timings in task_timing_info.items():
    fd_task = []
    for subject_id in subject_list:
        fd_values = load_fd(subject_id)
        if len(fd_values) == 0:
            continue

        # Extract FD values for each timing (onset and duration)
        for onset, duration in timings:
            fd_task.extend(fd_values[onset:onset + duration])

    task_fd_list.append(fd_task)

# Plot FD by task
plt.figure(figsize=(12, 8))
positions = np.arange(1, len(task_timing_info) + 1)
plt.violinplot(task_fd_list, positions, showextrema=False)
plt.boxplot(task_fd_list, widths=0.1, showfliers=False, patch_artist=True,
            boxprops={'color': 'blue', 'facecolor': 'lightgrey'},
            medianprops={'color': 'red'})
plt.xticks(positions, list(task_timing_info.keys()), rotation=45)
plt.ylim(0, 1.2)
plt.title("Task-Specific Framewise Displacement")
plt.xlabel("Tasks")
plt.ylabel("Framewise Displacement (mm)")
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()
plt.savefig(plots_dir / "task_specific_fd.png")
plt.close()

print('Plots were saved')