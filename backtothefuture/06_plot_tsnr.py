import nibabel as nib
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import numpy as np

# Paths
tsnr_path = "/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/tsnr_group_mean.nii.gz"
output_path = "/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/tsnr_grid_sagittal_gap.png"

# Load data
img = nib.load(tsnr_path)
data = np.squeeze(img.get_fdata())
print(data.shape[0] // 2)

# Figure properties
cmap = cm.get_cmap("jet").copy()
cmap.set_under("white")
vmin, vmax = 10, 150
n_rows, n_cols = 3, 3
gap_cols = 1  # one empty column between views
total_cols = 2 * n_cols + gap_cols  # total columns including gap
n_slices = n_rows * n_cols

# Slices to plot
#slice_indices = np.linspace(20, 75, n_slices, dtype=int)
slice_indices = [20, 27, 34, 41, 48, 55, 62, 68, 75]
fig, axes = plt.subplots(n_rows, total_cols, figsize=(24, 12), gridspec_kw=dict(wspace=0.02, hspace=0.01))

orientations = ['sagittal', 'axial']
for i_orient, orientation in enumerate(orientations):
    axis = {'sagittal': 0, 'axial': 2}[orientation]
    col_start = i_orient * (n_cols + (1 if i_orient > 0 else 0))  # skip a column for the gap

    for i, slice_idx in enumerate(slice_indices):
        row = i // n_cols
        col = col_start + (i % n_cols)
        ax = axes[row, col]

        if orientation == 'sagittal':
            img_slice = data[slice_idx, :, :].T
        elif orientation == 'axial':
            img_slice = data[:, :, slice_idx].T

        im = ax.imshow(img_slice, cmap=cmap, origin="lower", vmin=vmin, vmax=vmax)
        ax.axis("off")

# -------- Hide gap column --------
gap_col_index = n_cols  # between the two views
for row in range(n_rows):
    axes[row, gap_col_index].axis("off")

# Colourbar
cbar_ax = fig.add_axes([0.93, 0.15, 0.015, 0.7])
fig.colorbar(im, cax=cbar_ax)

# Save
plt.suptitle("TEMPORAL SIGNAL-TO-NOISE RATIO", fontsize=20, y=0.95)
plt.savefig(output_path, dpi=400, bbox_inches="tight")
plt.show()
