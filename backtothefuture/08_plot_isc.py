import nibabel as nib
import matplotlib.pyplot as plt
import numpy as np
from nilearn.image import resample_to_img

# === Paths ===
isc_group = "/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/isc/ISC_group.nii.gz"
anat_template = "/egor2/egor/MovieProject2/bids_data/derivatives/sub-01/backtothefuture/sub-01.results.20250211_214642/MNI152_2009_template_SSW.nii.gz"
output_path = "/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/isc/isc_map_over_anat_FDRcorr.png"

# === Load ISC map and t-map ===
isc_img = nib.load(isc_group)
data_5d = isc_img.get_fdata()
isc_data = np.squeeze(data_5d[..., 0])  # sub-brick 0: ISC
t_data   = np.squeeze(data_5d[..., 1])  # sub-brick 1: t-statistics

# === Load FDR q-map ===
qval_path = isc_group.replace(".nii.gz", "_qvals.nii.gz")
qval_img = nib.load(qval_path)
qval_data = np.squeeze(qval_img.get_fdata())  # single sub-brick

# === Create brain mask and apply FDR threshold ===
brain_mask = isc_data != 0
n_voxels = np.sum(brain_mask)
print(f"Number of voxels in mask: {n_voxels}")

fdr_alpha = 0.001
fdr_mask = (qval_data < fdr_alpha) & brain_mask
isc_data_masked = np.where(fdr_mask, isc_data, 0)

# === Load and resample anatomical image ===
anat_img = nib.load(anat_template)
anat_data_full = anat_img.get_fdata()
anat_data = np.squeeze(anat_data_full[..., 0])  # first sub-brick
anat_img = nib.Nifti1Image(anat_data, affine=anat_img.affine, header=anat_img.header)

anat_resampled_img = resample_to_img(anat_img, isc_img, interpolation="linear", force_resample=True)
anat_data = anat_resampled_img.get_fdata()

# === Check for any surviving voxels ===
if not np.any(fdr_mask):
    print("No voxels survived FDR correction!")
    exit()

# === Plot settings ===
vmin, vmax = np.percentile(isc_data_masked[isc_data_masked != 0], [5, 99])
anat_vmin, anat_vmax = np.percentile(anat_data[brain_mask], [1, 99])

cmap = plt.colormaps["plasma"].copy()
cmap.set_under("white")

n_rows, n_cols = 3, 3
gap_cols = 0
total_cols = 2 * n_cols + gap_cols
slice_indices = [20, 27, 34, 41, 48, 55, 62, 68, 75]
orientations = ['sagittal', 'axial']

fig, axes = plt.subplots(n_rows, total_cols, figsize=(28, 16), gridspec_kw=dict(wspace=0.02, hspace=0.01))

for i_orient, orientation in enumerate(orientations):
    axis = {'sagittal': 0, 'axial': 2}[orientation]
    col_start = i_orient * n_cols

    for i, slice_idx in enumerate(slice_indices):
        row = i // n_cols
        col = col_start + (i % n_cols)
        ax = axes[row, col]

        if orientation == 'sagittal':
            anat_slice = anat_data[slice_idx, :, :].T
            isc_slice = isc_data_masked[slice_idx, :, :].T
        elif orientation == 'axial':
            anat_slice = anat_data[:, :, slice_idx].T
            isc_slice = isc_data_masked[:, :, slice_idx].T

        ax.imshow(anat_slice, cmap="gray", vmin=anat_vmin, vmax=anat_vmax, origin="lower")
        isc_overlay = np.ma.masked_where(isc_slice == 0, isc_slice)
        ax.imshow(isc_overlay, cmap=cmap, vmin=vmin, vmax=vmax, alpha=0.75, origin="lower")
        ax.axis("off")

# Hide gap column
# gap_col_index = n_cols
# for row in range(n_rows):
#     axes[row, gap_col_index].axis("off")

# === Colorbar ===
cbar_ax = fig.add_axes([0.93, 0.15, 0.015, 0.7])
fig.colorbar(plt.cm.ScalarMappable(norm=plt.Normalize(vmin=vmin, vmax=vmax), cmap=cmap), cax=cbar_ax)

# === Save ===
plt.suptitle(f"FDR-corrected ISC (q < {fdr_alpha})", fontsize=25, y=0.95)
plt.savefig(output_path, dpi=600, bbox_inches="tight")
plt.show()
