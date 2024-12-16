#!/bin/bash


# Setup freesufer and directories
export FREESURFER_HOME=/tools/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export SUBJECTS_DIR=/data/elevchenko/MovieProject2/bids_data/derivatives/freesurfer/
export data_folder=/data/elevchenko/MovieProject2/bids_data

subjects="01 02 03 04 05 06 07 08 09 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44"

# Check if folder SUBJECTS_DIR exists
if [ -d "$SUBJECTS_DIR" ]; then
    echo "SUBJECTS_DIR exists..."
else
    echo "SUBJECTS_DIR doesn't exist. Creating one now..."
    mkdir -p "$SUBJECTS_DIR"
fi


# Run
for subj_id in 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44; do #$subjects; do

    if [[ $subj_id -eq "10" ]]; then
        # Use a different path for subject 10
        input_path="$data_folder/sub-${subj_id}/ses-002/anat/sub-10_ses-002_acq-highres_T1w.nii.gz"
    else
        # Default path for other subjects
        input_path="$data_folder/sub-${subj_id}/ses-001/anat/sub-${subj_id}_ses-001_T1w.nii.gz"
    fi

    echo $(freesurfer --version)
    echo "$subj_id freesurfer processing..."

    recon-all \
        -i "$input_path" \
        -s sub-"$subj_id" \
        -all
done
