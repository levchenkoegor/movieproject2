#!/bin/bash

# Base directory
export deriv_root="/egor2/egor/MovieProject2/bids_data/derivatives"

# Create a temporary list of tSNR files
tsnr_list="tsnr_group_inputs.txt"
rm -f $tsnr_list

# Loop over subjects and append valid tSNR paths
for subj_dir in "${deriv_root}"/sub-*/backtothefuture/sub-*.results.*; do
    tsnr_file="${subj_dir}"/tsnr.all_runs.*.masked.nii.gz
    found_file=$(ls $tsnr_file 2>/dev/null | head -n 1)
    if [ -f "$found_file" ]; then
        echo "$found_file" >> $tsnr_list
    fi
done

# Report number of files found
n=$(wc -l < $tsnr_list)
echo "Found $n subject tSNR maps."

# Merge into 4D file
3dTcat -prefix tsnr_group_4D.nii.gz $(cat $tsnr_list)

# Compute voxelwise mean and std
3dTstat -mean -prefix "$deriv_root"/group_analysis/backtothefuture/tsnr_group_mean.nii.gz tsnr_group_4D.nii.gz
3dTstat -stdev -prefix "$deriv_root"/group_analysis/backtothefuture/tsnr_group_std.nii.gz tsnr_group_4D.nii.gz

# remove intermediate file
rm tsnr_group_4D.nii.gz $tsnr_list
