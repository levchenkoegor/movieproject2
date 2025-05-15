#!/bin/bash

# -------- SETTINGS --------
# Template underlay (already aligned)
template="./bids_data/derivatives/sub-01/backtothefuture/sub-01.results.20250211_214642/MNI152_2009_template_SSW.nii.gz"

# Subjects to include in group average
subjects=("01" "02")

# Output directory
mkdir -p figures

# Temp file list
tsnr_files=()

# -------- STEP 1: Create group mean tSNR map for run-01 --------
echo "✅ Averaging tSNR maps for subjects: ${subjects[*]}"

for subj in "${subjects[@]}"; do
    tsnr_path="./bids_data/derivatives/sub-${subj}/backtothefuture"
    tsnr_file=$(find "$tsnr_path" -type f -name "tsnr.r01.${subj}.masked.nii.gz" | head -n 1)

    if [[ -f "$tsnr_file" ]]; then
        echo "  ➤ Found: $tsnr_file"
        tsnr_files+=("$tsnr_file")
    else
        echo "  ⚠️ Missing tSNR for sub-${subj}, skipping."
    fi
done

if [ ${#tsnr_files[@]} -eq 0 ]; then
    echo "❌ No tSNR files found. Exiting."
    exit 1
fi

# Compute group average
group_mean_tsnr="figures/tsnr_group_r01.nii"
3dMean -prefix "$group_mean_tsnr" "${tsnr_files[@]}"

# -------- STEP 2: Generate montages with @chauffeur_afni --------

# Sagittal view
@chauffeur_afni \
    -ulay "$template" \
    -olay "$group_mean_tsnr" \
    -prefix figures/fig_tsnr_sag \
    -montx 5 -monty 3 \
    -opacity 9 \
    -pbar_posonly \
    -do_clean \
    -no_axi -no_cor \
    -set_dicom_xyz 0 0 0

# Axial view
@chauffeur_afni \
    -ulay "$template" \
    -olay "$group_mean_tsnr" \
    -prefix figures/fig_tsnr_axi \
    -montx 5 -monty 3 \
    -opacity 9 \
    -pbar_posonly \
    -do_clean \
    #-no_sag -no_cor \
    #-set_dicom_xyz 0 0 0

# -------- STEP 3: Combine into single panel --------

if [[ -f figures/fig_tsnr_sag.jpg && -f figures/fig_tsnr_axi.jpg ]]; then
    montage figures/fig_tsnr_sag.jpg figures/fig_tsnr_axi.jpg \
        -tile 2x1 -geometry +10+10 figures/fig_tsnr_combined.jpg
    echo "✅ Combined figure saved to: figures/fig_tsnr_combined.jpg"
else
    echo "❌ Montage images missing. Check @chauffeur_afni output."
fi
