#!/bin/bash


# Setup freesurfer and directories
export FREESURFER_HOME=/tools/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export SUBJECTS_DIR=/data/elevchenko/MovieProject2/bids_data/derivatives/freesurfer/
export data_folder=/data/elevchenko/MovieProject2/bids_data

# Extract subject IDs dynamically from the bids_data folder
subjects=$(ls -d $data_folder/sub-* | awk -F'/' '{print $NF}' | sed 's/sub-//')

# Check if folder SUBJECTS_DIR exists
if [ -d "$SUBJECTS_DIR" ]; then
    echo "SUBJECTS_DIR exists..."
else
    echo "SUBJECTS_DIR doesn't exist. Creating one now..."
    mkdir -p "$SUBJECTS_DIR"
fi

# Run
for subj_id in $subjects; do

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
