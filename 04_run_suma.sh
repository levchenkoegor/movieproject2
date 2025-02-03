#!/bin/bash


# Setup directories
export FREESURFER_HOME=/tools/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh

export data_folder=/data/elevchenko/MovieProject2/bids_data

# Extract subject IDs dynamically from the bids_data folder
subjects=$(ls -d $data_folder/derivatives/freesurfer/sub-* | awk -F'/' '{print $NF}' | sed 's/sub-//')

for subj_id in $subjects; do

    # Warp away
    OMP_NUM_THREADS=16 @SUMA_Make_Spec_FS \
      -fspath "$data_folder/derivatives/freesurfer/sub-${subj_id}" \
      -NIFTI \
      -sid sub-"${subj_id}"

    # Compress results
    gzip "${data_folder}"/derivatives/freesurfer/sub-"${subj_id}"/SUMA/*nii
    gzip "${data_folder}"/derivatives/freesurfer/sub-"${subj_id}"/SUMA/*gii

done
