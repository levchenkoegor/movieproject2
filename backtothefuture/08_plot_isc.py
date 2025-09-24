import nibabel as nib
import matplotlib.pyplot as plt
import numpy as np
from nilearn.image import resample_to_img
import matplotlib as mpl

# === Paths ===
isc_group = "/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/isc/ISC_group.nii.gz"
anat_template = "/egor2/egor/MovieProject2/bids_data/derivatives/sub-01/backtothefuture/sub-01.results.20250211_214642/MNI152_2009_template_SSW.nii.gz"
output_path = "/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/isc/isc_map_over_anat_FDRcorr.png"

# === Fonts ===
mpl.rcParams.update({
    "font.size": 18,          # base
    "axes.titlesize": 20,
    "axes.labelsize": 20,
    "xtick.labelsize": 16,
    "ytick.labelsize": 16
})

# === Load ISC map, t-map, q-map ===
isc_img = nib.load(isc_group)
data_5d = isc_img.get_fdata()
isc_data = np.squeeze(data_5d[..., 0])
t_data   = np.squeeze(data_5d[..., 1])

qval_path = isc_group.replace(".nii.gz", "_qvals.nii.gz")
qval_img = nib.load(qval_path)
qval_data = np.squeeze(qval_img.get_fdata())

# === Brain/FDR masks ===
brain_mask = isc_data != 0
fdr_alpha = 0.001
fdr_mask = (qval_data < fdr_alpha) & brain_mask
if not np.any(fdr_mask):
    raise RuntimeError("No voxels survived FDR correction!")

# === Anatomy to ISC space ===
anat_img = nib.load(anat_template)
anat_data_full = anat_img.get_fdata()
anat_first = np.squeeze(anat_data_full[..., 0])
anat_img = nib.Nifti1Image(anat_first, affine=anat_img.affine, header=anat_img.header)
anat_resampled_img = resample_to_img(anat_img, isc_img, interpolation="linear", force_resample=True)
anat_data = anat_resampled_img.get_fdata()

# === Values / colormap ===
isc_data_masked = np.where(fdr_mask, isc_data, np.nan)  # use NaN so it's 'bad' and transparent
vmin, vmax = np.nanpercentile(isc_data_masked, [5, 99])
anat_vmin, anat_vmax = np.percentile(anat_data[brain_mask], [1, 99])

# fully transparent for NaNs (bad) and values < vmin (under)
cmap = plt.colormaps["plasma"].with_extremes(bad=(0,0,0,0), under=(0,0,0,0))

# === Layout ===
n_rows, n_cols = 3, 3
orientations = ["sagittal", "axial"]
total_cols = n_cols * len(orientations)

fig, axes = plt.subplots(
    n_rows, total_cols,
    figsize=(26, 15),
    gridspec_kw=dict(wspace=0.0, hspace=0.0),
    facecolor="black"
)

# ensure axes backgrounds are black and no margins
for ax in axes.flat:
    ax.set_facecolor("black")
    ax.margins(0)

# pick slices; you can auto-space these if you like
slice_indices = [20, 27, 34, 41, 48, 55, 62, 68, 75]

for i_orient, orientation in enumerate(orientations):
    axis = {"sagittal": 0, "axial": 2}[orientation]
    col_start = i_orient * n_cols

    for i, s in enumerate(slice_indices):
        r = i // n_cols
        c = col_start + (i % n_cols)
        ax = axes[r, c]

        if orientation == "sagittal":
            anat_slice = anat_data[s, :, :].T
            isc_slice  = isc_data_masked[s, :, :].T
        elif orientation == "axial":
            anat_slice = anat_data[:, :, s].T
            isc_slice  = isc_data_masked[:, :, s].T

        # anatomy
        ax.imshow(
            anat_slice, cmap="gray",
            vmin=anat_vmin, vmax=anat_vmax,
            origin="lower", interpolation="nearest"
        )

        # ISC overlay (transparent where NaN or <vmin)
        ax.imshow(
            isc_slice, cmap=cmap,
            vmin=vmin, vmax=vmax, alpha=0.85,
            origin="lower", interpolation="nearest"
        )

        ax.set_axis_off()
        ax.set_aspect("equal")

# === Colorbar (tight, big label) ===
# Reserve a slim strip for the colorbar so we can keep zero spacing between images
plt.subplots_adjust(left=0.01, right=0.92, top=0.93, bottom=0.02, wspace=0.0, hspace=0.0)
cbar_ax = fig.add_axes([0.935, 0.12, 0.018, 0.76])  # [left, bottom, width, height]
sm = plt.cm.ScalarMappable(norm=plt.Normalize(vmin=vmin, vmax=vmax), cmap=cmap)
cbar = fig.colorbar(sm, cax=cbar_ax)

# Set ticks and labels to white
cbar.ax.tick_params(color="white", labelcolor="white", labelsize=18)
cbar.outline.set_edgecolor("white")  # make the frame white too
cbar.set_label("Inter-subject correlation (r)", fontsize=22, color="white", labelpad=25)

# === Title & save ===
fig.suptitle(f"Inter-subject correlation map (q < {fdr_alpha})", fontsize=26, color="white", y=0.92)
plt.savefig(output_path, dpi=600, facecolor=fig.get_facecolor(), bbox_inches="tight")
plt.show()
