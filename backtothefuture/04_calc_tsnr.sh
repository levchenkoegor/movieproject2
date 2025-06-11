#!/bin/bash

# Base path to derivatives
export deriv_root=/egor2/egor/MovieProject2/bids_data/derivatives

# Find all subjects with a backtothefuture results folder
subjects=$(find $deriv_root -maxdepth 3 -type d -name "sub-*.results.*" -path "*/backtothefuture/*" | sed -E 's|.*/sub-([0-9]+)\.results.*|\1|' | sort -u)

# Loop through subjects
for subj in $subjects; do
    echo "Processing subject: sub-${subj}"

    # Handle exceptions: number of runs per subject
    runs="01 02 03"
    if [[ "$subj" == "24" || "$subj" == "36" ]]; then
        runs="01 02 03 04"
    fi

    # Get the AFNI results directory for this subject
    res_dir=$(find "${deriv_root}"/sub-"${subj}"/backtothefuture -maxdepth 1 -type d -name "sub-${subj}.results.*" | head -n 1)
    if [ -z "$res_dir" ]; then
        echo "No results directory found for sub-${subj}, skipping."
        continue
    fi

    # ------------- RUN-WISE tSNR -------------
    for run in $runs; do
        scale_file="${res_dir}/pb04.${subj}.r${run}.scale+tlrc.HEAD"
        if [ ! -f "$scale_file" ]; then
            echo "Missing scale file for run r${run}, skipping."
            continue
        fi

        echo "Computing tSNR for sub-${subj}, run-r${run}..."
        3dTstat -tsnr \
            -prefix "${res_dir}/tsnr.r${run}.${subj}.nii.gz" \
            "${res_dir}/pb04.${subj}.r${run}.scale+tlrc"

        # Masked version
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

    # ------------- CONCATENATED tSNR -------------
    echo "Concatenating runs and computing total tSNR for sub-${subj}..."

    # Build list of valid input files
    scale_inputs=()
    for run in $runs; do
        scale_file="${res_dir}/pb04.${subj}.r${run}.scale+tlrc.HEAD"
        if [ -f "$scale_file" ]; then
            scale_inputs+=("${res_dir}/pb04.${subj}.r${run}.scale+tlrc")
        fi
    done

    if [ "${#scale_inputs[@]}" -gt 1 ]; then

      3dTcat -prefix "${res_dir}/pb04.${subj}.all_runs.scale+tlrc" "${scale_inputs[@]}"
      3dTstat -tsnr -prefix "${res_dir}/tsnr.all_runs.${subj}.nii.gz" \
              "${res_dir}/pb04.${subj}.all_runs.scale+tlrc"

      # Masked version
      3dcalc -a "${res_dir}/tsnr.all_runs.${subj}.nii.gz" \
             -b "$mask_file" \
             -expr 'a*step(b)' \
             -prefix "${res_dir}/tsnr.all_runs.${subj}.masked.nii.gz"
    else
        echo "Not enough valid runs to concatenate for sub-${subj}, skipping total tSNR."
    fi
done

# Final compression step
find $deriv_root -type f \( -name "*.nii" -o -name "*.BRIK" \) -exec gzip -f "{}" \;
