import nibabel as nib
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import numpy as np


# Create colormap and set 'under' color to white (or any other)
cmap = cm.get_cmap("jet").copy()
cmap.set_under("white")

# -------- Load data --------
tsnr_path = "figures/tsnr_group_r01.nii.gz"
img = nib.load(tsnr_path)
data = np.squeeze(img.get_fdata())  # ensure 3D
affine = img.affine

for orientation in ['sagittal', 'coronal', 'axial']:
    axis = {'sagittal': 0, 'coronal': 1, 'axial': 2}[orientation]

    # -------- Choose informative slices --------
    n_rows, n_cols = 4, 3
    n_slices = n_rows * n_cols

    # Find non-empty range for selected axis
    slice_indices = np.linspace(20, 75, n_slices, dtype=int)

    # -------- Plot --------
    fig, axes = plt.subplots(n_rows, n_cols, figsize=(10, 12), gridspec_kw=dict(wspace=0.01, hspace=0.01))
    vmin, vmax = 10, 150

    for ax, slice_idx in zip(axes.ravel(), slice_indices):
        if orientation == 'sagittal':
            img_slice = data[slice_idx, :, :].T
        elif orientation == 'coronal':
            img_slice = data[:, slice_idx, :].T
        elif orientation == 'axial':
            img_slice = data[:, :, slice_idx].T

        im = ax.imshow(img_slice, cmap=cmap, origin="lower", vmin=vmin, vmax=vmax)
        ax.axis("off")

    # -------- Colorbar --------
    cbar_ax = fig.add_axes([0.92, 0.15, 0.015, 0.7])  # [left, bottom, width, height]
    fig.colorbar(im, cax=cbar_ax)

    # -------- Title and save --------
    plt.suptitle(f"TEMPORAL SIGNAL-TO-NOISE RATIO\n\n {orientation.upper()}", fontsize=20, y=0.98)
    #plt.tight_layout(rect=[0, 0, 0.9, 0.95])
    plt.savefig(f"figures/tsnr_grid_{orientation}.png", dpi=300, bbox_inches="tight")
    plt.show()
