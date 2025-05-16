#!/bin/bash

# Base path to derivatives
export deriv_root=/data/elevchenko/MovieProject2/bids_data/derivatives

# Find all subjects with a backtothefuture results folder
subjects=$(find $deriv_root -maxdepth 3 -type d -name "sub-*.results.*" -path "*/backtothefuture/*" | sed -E 's|.*/sub-([0-9]+)\.results.*|\1|' | sort -u)

# Define run indices (adjust if some subjects have more or fewer runs)
subjects="01 02"  # Test
runs="01 02 03"

# Loop through subjects
for subj in $subjects; do
    echo "Processing subject: sub-${subj}"

    # Get the AFNI results directory for this subject
    res_dir=$(find "${deriv_root}"/sub-"${subj}"/backtothefuture -maxdepth 1 -type d -name "sub-${subj}.results.*" | head -n 1)
    if [ -z "$res_dir" ]; then
        echo "No results directory found for sub-${subj}, skipping."
        continue
    fi

    for run in $runs; do
        scale_file="${res_dir}/pb04.${subj}.r${run}.scale+tlrc.HEAD"
        if [ ! -f "$scale_file" ]; then
            echo "Missing scale file for run r${run}, skipping."
            continue
        fi

        echo "Computing unmasked tSNR for sub-${subj}, run-r${run}..."
        # Compute unmasked tSNR
        3dTstat -tsnr \
            -prefix "${res_dir}/tsnr.r${run}.${subj}.nii.gz" \
            "${res_dir}/pb04.${subj}.r${run}.scale+tlrc"

        # Compute masked tSNR if mask exists
        mask_file="${res_dir}/mask_epi_anat.${subj}+tlrc.HEAD"
        if [ -f "$mask_file" ]; then
            echo "Computing masked tSNR for sub-${subj}, run-r${run}..."
            3dcalc -a "${res_dir}/tsnr.r${run}.${subj}.nii.gz" \
                   -b "${res_dir}/mask_epi_anat.${subj}+tlrc" \
                   -expr 'a*step(b)' \
                   -prefix "${res_dir}/tsnr.r${run}.${subj}.masked.nii.gz"
        else
            echo "No mask found for sub-${subj}, skipping mask application."
        fi
    done
done

# Zip outputs
find /data/elevchenko/MovieProject2/bids_data/derivatives -type f \( -name "*.nii" -o -name "*.BRIK" \) -exec gzip -f "{}" \;
