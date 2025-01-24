#!/bin/bash


# Setup directories
export FREESURFER_HOME=/tools/freesurfer
export data_folder=/data/elevchenko/MovieProject2/bids_data

#subjects="01 02 03 04 05 06 07 08 09 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44"

subjects="01 02"

for subj_id in $subjects; do

    # Warp away
    OMP_NUM_THREADS=16 @SUMA_Make_Spec_FS \
      -fs_setup $FREESURFER_HOME/SetUpFreeSurfer.sh \
      -fspath "$data_folder/derivatives/freesurfer/sub-${subj_id}" \
      -NIFTI \
      -sid sub-"${subj_id}"

    # Compress results
    gzip "${data_folder}"/derivatives/freesurfer/sub-"${subj_id}"/SUMA/*nii
    gzip "${data_folder}"/derivatives/freesurfer/sub-"${subj_id}"/SUMA/*gii

done
