import subprocess
from pathlib import Path
import nibabel as nib
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from nilearn import plotting
from nilearn.image import mean_img

# Define the directory containing the derivatives
base_dir = Path('/data/elevchenko/MovieProject2/')
deriv_dir = base_dir / 'bids_data' / 'derivatives'
plots_dir = deriv_dir / 'plots'
plots_dir.mkdir(parents=True, exist_ok=True)  # Ensure plots directory exists

# Initialize a container for group-level tSNR data
group_tsnr = []
tsnr_images = []  # Store NIfTI tSNR images for group-level calculation

# Loop through each subject directory
for subject_dir in sorted(deriv_dir.glob("sub-*")):
    subject_id = subject_dir.name  # e.g., "sub-01"
    somatotopy_dir = subject_dir / "somatotopy" / f"{subject_id}.results"

    # Find the tSNR file
    tsnr_brik_file = list(somatotopy_dir.glob("TSNR.*+orig.BRIK"))
    tsnr_head_file = list(somatotopy_dir.glob("TSNR.*+orig.HEAD"))
    if not tsnr_brik_file or not tsnr_head_file:
        print(f"Warning: No TSNR file found for {subject_id}")
        continue
    tsnr_brik_file = tsnr_brik_file[0]  # Take the first match
    tsnr_head_file = tsnr_head_file[0]

    # Convert BRIK/HEAD to NIfTI using AFNI's 3dAFNItoNIFTI
    tsnr_nifti_file = somatotopy_dir / f"TSNR.{subject_id}.nii.gz"
    if not tsnr_nifti_file.exists():  # Only convert if not already done
        try:
            subprocess.run(
                ["3dAFNItoNIFTI", "-prefix", str(tsnr_nifti_file), str(tsnr_head_file)],
                check=True,
            )
            print(f"Converted {tsnr_head_file} to {tsnr_nifti_file}")
        except subprocess.CalledProcessError as e:
            print(f"Error converting {subject_id}: {e}")
            continue

    # Load the converted NIfTI file
    tsnr_img = nib.load(str(tsnr_nifti_file))
    tsnr_data = tsnr_img.get_fdata()

    # Add to the list of tSNR images for group calculation
    tsnr_images.append(tsnr_img)

    # Mask out non-brain voxels (assume zero or NaN outside the brain)
    tsnr_data = tsnr_data[np.isfinite(tsnr_data) & (tsnr_data > 0)]

    # Compute summary statistics for this subject
    subject_stats = {
        "subject": subject_id,
        "mean_tSNR": np.mean(tsnr_data),
        "median_tSNR": np.median(tsnr_data),
        "std_tSNR": np.std(tsnr_data),
    }
    group_tsnr.append(subject_stats)

# Convert the group-level data to a pandas DataFrame
df_tsnr = pd.DataFrame(group_tsnr)

# Save the results to a CSV file
output_csv = base_dir / 'analysis' / 'somatotopy' / 'task_somatotopy_group_tsnr_summary.csv'
output_csv.parent.mkdir(parents=True, exist_ok=True)  # Ensure output directory exists
df_tsnr.to_csv(output_csv, index=False)
print(f"Group tSNR summary saved to '{output_csv}'.")

# Plot the results: Bar plot of mean tSNR across subjects
plt.figure(figsize=(10, 6))
plt.bar(df_tsnr['subject'], df_tsnr['mean_tSNR'], color='skyblue')
plt.xticks(rotation=90)
plt.title("Mean tSNR Across Subjects")
plt.ylabel("Mean tSNR")
plt.xlabel("Subjects")
plt.tight_layout()
plt.savefig(plots_dir / 'task-somatotopy_mean_tsnr_plot.png')
plt.show()

# Plot the results: Histogram of mean tSNR values
plt.figure(figsize=(10, 6))
plt.hist(df_tsnr['mean_tSNR'], bins=20, color='lightgreen', edgecolor='black')
plt.title("Distribution of Mean tSNR Across Subjects")
plt.xlabel("Mean tSNR")
plt.ylabel("Frequency")
plt.tight_layout()
plt.savefig(plots_dir / 'task-somatotopy_mean_tsnr_distribution.png')
plt.show()

# Compute the group-level tSNR map (mean of all subjects)
group_tsnr_map_path = deriv_dir / 'group_tsnr.nii.gz'
if tsnr_images:
    group_tsnr_img = mean_img(tsnr_images)  # Compute mean image across subjects
    group_tsnr_img.to_filename(str(group_tsnr_map_path))
    print(f"Group tSNR map saved to '{group_tsnr_map_path}'.")

    # Create slice views
    slicing_plot_path = plots_dir / 'task-somatotopy_tsnr_slices.png'
    plotting.plot_epi(
        str(group_tsnr_map_path),
        display_mode='z',
        cut_coords=8,
        title="Axial Slices of Group-Level tSNR",
        output_file=str(slicing_plot_path)
    )
    print(f"Slice views saved to '{slicing_plot_path}'.")

    # Glass brain view
    glass_brain_plot_path = plots_dir / 'task-somatotopy_tsnr_glass_brain.png'
    plotting.plot_glass_brain(
        str(group_tsnr_map_path),
        threshold=0.5,
        colorbar=True,
        title="Glass Brain View of Group-Level tSNR",
        output_file=str(glass_brain_plot_path)
    )
    print(f"Glass brain view saved to '{glass_brain_plot_path}'.")
else:
    print("No tSNR images found. Skipping group-level tSNR map calculation and visualizations.")

print('Plots were saved')
