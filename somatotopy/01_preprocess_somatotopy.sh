#!/bin/bash

# Paths
export data_folder=/data/elevchenko/MovieProject2/bids_data
export stim_folder=/data/elevchenko/MovieProject2/stimuli
export fs_folder=/data/elevchenko/MovieProject2/bids_data/derivatives/freesurfer

# Maximum number of parallel jobs nad threads
max_jobs=14

# Extract subject IDs dynamically from the bids_data folder
subjects=$(ls -d $data_folder/sub-* | awk -F'/' '{print $NF}' | sed 's/sub-//' | sort -n)
echo "The list of subjects to be preprocessed: ${subjects[@]}"


# Run AFNI
for subject_id in $subjects; do

    (
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

      # Run afni_proc.py to create preproc script
      timestamp=$(date +%Y%m%d_%H%M%S)
      afni_proc.py \
          -subj_id sub-"$subject_id" \
          -script "$script_path.$timestamp" \
          -out_dir "$results_path.$timestamp" \
          -dsets "$data_folder"/sub-"$subject_id"/ses-002/func/*task-motor_run-001_bold*.nii.gz \
                 "$data_folder"/sub-"$subject_id"/ses-002/func/*task-motor_run-002_bold*.nii.gz \
          -blocks tcat align tlrc volreg mask blur scale regress \
          -blip_reverse_dset "$data_folder"/sub-"$subject_id"/ses-002/fmap/*_acq-motor_dir-PA*.nii.gz \
          -tcat_remove_first_trs 8 \
          -radial_correlate_blocks tcat volreg \
          -copy_anat "$anat_path" \
          -anat_has_skull no \
          -anat_follower anat_w_skull anat "$data_folder/derivatives/sub-${subject_id}/SSwarper/anatU.sub-${subject_id}.nii.gz" \
          -anat_follower_ROI aaseg    anat "$fs_folder/sub-${subject_id}/SUMA/aparc.a2009s+aseg.nii.gz" \
          -anat_follower_ROI aeseg    epi  "$fs_folder/sub-${subject_id}/SUMA/aparc.a2009s+aseg.nii.gz" \
          -anat_follower_ROI fsvent   epi  "$fs_folder/sub-${subject_id}/SUMA/fs_ap_latvent.nii.gz" \
          -anat_follower_ROI fswm     epi  "$fs_folder/sub-${subject_id}/SUMA/fs_ap_wm.nii.gz" \
          -anat_follower_ROI fsgm     epi  "$fs_folder/sub-${subject_id}/SUMA/aparc+aseg_REN_gm.nii.gz" \
          -anat_follower_erode fsvent fswm \
          -align_opts_aea -cost lpc+ZZ -giant_move -check_flip \
          -tlrc_base MNI152_2009_template_SSW.nii.gz \
          -tlrc_NL_warp \
          -tlrc_NL_warped_dsets \
            "$data_folder/derivatives/sub-${subject_id}/SSwarper/anatQQ.sub-${subject_id}.nii.gz" \
            "$data_folder/derivatives/sub-${subject_id}/SSwarper/anatQQ.sub-${subject_id}.aff12.1D" \
            "$data_folder/derivatives/sub-${subject_id}/SSwarper/anatQQ.sub-${subject_id}_WARP.nii.gz" \
          -volreg_align_to MIN_OUTLIER \
          -volreg_post_vr_allin yes \
          -volreg_pvra_base_index MIN_OUTLIER \
          -volreg_align_e2a \
          -volreg_tlrc_warp \
          -volreg_opts_vr -twopass -twodup -maxdisp1D mm'.r$run' \
          -volreg_compute_tsnr yes \
          -mask_opts_automask -clfrac 0.10 \
          -mask_epi_anat yes \
          -blur_to_fwhm -blur_size 4 \
          -regress_motion_per_run \
          -regress_ROI_PC fsvent 3 \
          -regress_ROI_PC_per_run fsvent \
          -regress_make_corr_vols aeseg fsvent \
          -regress_anaticor_fast \
          -regress_anaticor_label fswm \
          -regress_apply_mot_types demean deriv \
          -regress_est_blur_epits \
          -regress_est_blur_errts \
          -regress_run_clustsim no \
          -regress_bandpass 0.01 1 \  # Do we need to bandpass? Runs are short
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
          -regress_reml_exec \
          -remove_preproc_files \
          -html_review_style pythonic

      tcsh -xef "$script_path.$timestamp" 2>&1 | tee "$output_path.$timestamp"

      # Compress files for this subject
      echo "Compressing files for subject $subject_id..."
      find "$results_path.$timestamp" -type f \( -name "*.nii" -o -name "*.BRIK" \) -exec gzip -f "{}" \;
      echo "Compression for subject $subject_id completed."
    ) &

    # Limit the number of parallel jobs
    while [ "$(jobs -p | wc -l)" -ge "$max_jobs" ]; do
        sleep 10
    done
done

# Wait for all background jobs to finish
wait
