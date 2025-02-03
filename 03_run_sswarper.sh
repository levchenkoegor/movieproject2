#!/bin/bash


# Setup directories
export data_folder=/data/elevchenko/MovieProject2/bids_data

# Extract subject IDs dynamically from the bids_data folder
subjects=$(ls -d $data_folder/sub-* | awk -F'/' '{print $NF}' | sed 's/sub-//')

# Run
for subj_id in $subjects; do

    if [[ $subj_id -eq "10" ]]; then
        # Use a different path for subject 10
        input_path="$data_folder/sub-${subj_id}/ses-002/anat/sub-10_ses-002_acq-highres_T1w.nii.gz"
    else
        # Default path for other subjects
        input_path="$data_folder/sub-${subj_id}/ses-001/anat/sub-${subj_id}_ses-001_T1w.nii.gz"
    fi

    # Warp away
    OMP_NUM_THREADS=16 @SSwarper \
        -input "$input_path" \
        -subid sub-"$subj_id" \
        -odir "$data_folder/derivatives/sub-${subj_id}/SSwarper" \
        -base MNI152_2009_template_SSW.nii.gz

    # Compress results
    gzip "${data_folder}"/derivatives/sub-"${subj_id}"/SSwarper/*nii

done
