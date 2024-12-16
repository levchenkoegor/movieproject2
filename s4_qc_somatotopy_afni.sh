#!/bin/bash

# Paths
export data_folder=/data/elevchenko/MovieProject2/bids_data
export stim_folder=/data/elevchenko/MovieProject2/stimuli

subjects="01 02 03 04 05 06 07 08 09 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44"

# Run AFNI
for subject_id in $subjects; do

    echo "Processing subject $subject_id"
    subject_folder="$data_folder/derivatives/sub-$subject_id/somatotopy"
    script_path="$subject_folder/proc.sub-$subject_id"
    output_path="$subject_folder/output.proc.sub-$subject_id"
    results_path="$subject_folder/sub-$subject_id.results"

    # Create target directory if it does not exist
    if [ ! -d "$subject_folder" ]; then
        mkdir -p "$subject_folder"
        echo "Created directory $subject_folder"
    fi

    afni_proc.py \
        -subj_id sub-"$subject_id" \
        -script "$script_path" \
        -out_dir "$results_path" \
        -dsets "$data_folder"/sub-"$subject_id"/ses-002/func/*task-motor_run-001_bold*.nii.gz \
               "$data_folder"/sub-"$subject_id"/ses-002/func/*task-motor_run-002_bold*.nii.gz \
        -blocks tcat volreg scale regress \
        -blip_reverse_dset "$data_folder"/sub-"$subject_id"/ses-002/fmap/*_acq-motor_dir-PA*.nii.gz \
        -tcat_remove_first_trs 8 \
        -radial_correlate_blocks volreg \
        -volreg_align_to MIN_OUTLIER \
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
        -regress_opts_3dD -num_stimts 8 -local_times \
                -stim_label 1 LeftFoot \
                -stim_label 2 LeftHand \
                -stim_label 3 LeftFace \
                -stim_label 4 LeftTongue \
                -stim_label 5 RightFoot \
                -stim_label 6 RightHand \
                -stim_label 7 RightFace \
                -stim_label 8 RightTongue \
                -stim_times_AM1 1 "$stim_folder/task-somatotopy_condition-leftfoot_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 2 "$stim_folder/task-somatotopy_condition-lefthand_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 3 "$stim_folder/task-somatotopy_condition-leftface_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 4 "$stim_folder/task-somatotopy_condition-lefttongue_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 5 "$stim_folder/task-somatotopy_condition-rightfoot_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 6 "$stim_folder/task-somatotopy_condition-righthand_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 7 "$stim_folder/task-somatotopy_condition-rightface_run-both.1D" 'dmUBLOCK(1)' \
                -stim_times_AM1 8 "$stim_folder/task-somatotopy_condition-righttongue_run-both.1D" 'dmUBLOCK(1)' \
                -gltsym /data/elevchenko/MovieProject2/analysis/somatotopy_GLTsym.1D \
                -glt_label 1 'LeftFootVSRightFoot' \
                -glt_label 2 'LeftHandVSRightHand' \
                -glt_label 3 'LeftFaceVSRightFace' \
                -glt_label 4 'LeftTongueVSRightTongue' \
                -glt_label 5 'FaceVSFoot' \
                -glt_label 6 'FaceVSHand' \
                -glt_label 7 'FaceVSTongue' \
                -glt_label 8 'HandVSFoot' \
                -glt_label 9 'HandVSTongue' \
                -glt_label 10 'FootVSTongue' \
        -html_review_style pythonic

    tcsh -xef "$script_path" 2>&1 | tee "$output_path"
done
