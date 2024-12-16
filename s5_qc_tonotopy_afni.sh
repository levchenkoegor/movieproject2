#!/bin/bash

# Paths
export data_folder=/data/elevchenko/MovieProject2/bids_data
export stim_folder=/data/elevchenko/MovieProject2/stimuli

# Set up freesurfer for bbregister command
export FREESURFER_HOME=/tools/freesurfer
export SUBJECTS_DIR=/data/elevchenko/MovieProject2/bids_data/derivatives/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh

subjects="01 02 03 04 05 06 07 08 09 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44"

# Run AFNI
# sub-05 and 06: no tono
# sub-04, 08, 34: no Day 2
# The default sequence of runs is 'down1' and 'up1'
for subject_id in 01 02 22 35; do #$subjects; do

    # Define paths for easier files manipulations
    echo "Processing subject $subject_id"
    subject_folder="$data_folder/derivatives/sub-$subject_id/tonotopy"
    script_path="$subject_folder/proc.sub-$subject_id"
    output_path="$subject_folder/output.proc.sub-$subject_id"
    results_path="$subject_folder/sub-$subject_id.results"

    # Create target directory if it does not exist
    if [ ! -d "$subject_folder" ]; then
        mkdir -p "$subject_folder"
        echo "Created directory $subject_folder"
    fi

    # Run afni proc py
    afni_proc.py -subj_id "$subject_id" \
        -script "$script_path" \
        -out_dir "$results_path" \
        -dsets "$data_folder"/sub-"$subject_id"/ses-002/func/*task-tonotopy_run-001_bold*.nii.gz \
               "$data_folder"/sub-"$subject_id"/ses-002/func/*task-tonotopy_run-002_bold*.nii.gz \
        -blip_reverse_dset "$data_folder"/sub-"$subject_id"/ses-002/fmap/*acq-tonotopy*.nii.gz \
        -blocks tcat volreg scale regress \
        -tcat_remove_first_trs 8 \
        -radial_correlate_blocks volreg \
        -volreg_opts_vr -twopass -twodup -maxdisp1D mm \
        -volreg_compute_tsnr yes \
        -remove_preproc_files \
        -regress_motion_per_run \
        -regress_censor_outliers 0.05 \
        -regress_censor_motion 0.3 \
        -regress_compute_fitts \
        -regress_apply_mot_types demean deriv \
        -regress_run_clustsim no \
        -regress_show_df_info yes \
        -regress_reml_exec \
        -regress_stim_times "$stim_folder"/task-tonotopy_condition-*Hz.1D \
        -regress_basis 'BLOCK(6.4, 1)' \
        -regress_stim_labels 0175Hz 0247Hz 0350Hz 0495Hz 0700Hz 0990Hz 1400Hz 1980Hz 2800Hz 3960Hz \
        -regress_opts_3dD -local_times \
            -gltsym 'SYM: -0175Hz -0247Hz -0350Hz -0495Hz +0990Hz +1400Hz +1980Hz +2800Hz +3960Hz' \
            -glt_label 1 hiVsLo \
        -html_review_style pythonic

    tcsh -xef "$script_path" 2>&1 | tee "$output_path"


    # Rename files with more meaningful names
    3dcalc -a "$results_path"/pb02."$subject_id".r01.volreg+orig.BRIK -expr 'a' -prefix "$results_path"/tono_down1_ver1
    3dcalc -a "$results_path"/pb02."$subject_id".r02.volreg+orig.BRIK -expr 'a' -prefix "$results_path"/tono_up1_ver1

    3dcalc -a "$results_path"/vr_base+orig. -expr 'a' -prefix "$results_path"/vr_base.nii.gz

    # This tells bbregister to create a data file with all the registration parameters needed to align the T2 image to the associated T1 image.
    bbregister --s "$subject_id" --mov "$results_path"/vr_base.nii.gz --reg "$output_path"/"$subject_id"-tono-register.dat --T2

done
