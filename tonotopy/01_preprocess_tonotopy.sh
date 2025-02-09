#!/bin/bash

# Paths
export data_folder=/data/elevchenko/MovieProject2/bids_data
export stim_folder=/data/elevchenko/MovieProject2/stimuli
export fs_folder=/data/elevchenko/MovieProject2/bids_data/derivatives/freesurfer

# Set up freesurfer for bbregister command
export FREESURFER_HOME=/tools/freesurfer
export SUBJECTS_DIR=/data/elevchenko/MovieProject2/bids_data/derivatives/freesurfer/
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Maximum number of parallel jobs nad threads
max_jobs=14

# Extract subject IDs dynamically from the bids_data folder
subjects=$(ls -d $data_folder/sub-* | awk -F'/' '{print $NF}' | sed 's/sub-//' | sort -n)
echo "The list of subjects to be preprocessed: ${subjects[@]}"

subjects="01 07" # test
# Run AFNI
for subject_id in $subjects; do

    (
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

      # Run afni_proc.py to create preproc script
      timestamp=$(date +%Y%m%d_%H%M%S)
      afni_proc.py \
          -subj_id "$subject_id" \
          -script "$script_path.$timestamp" \
          -out_dir "$results_path.$timestamp" \
          -dsets "$data_folder"/sub-"$subject_id"/ses-002/func/*task-tonotopy_run-001_bold*.nii.gz \
                 "$data_folder"/sub-"$subject_id"/ses-002/func/*task-tonotopy_run-002_bold*.nii.gz \
          -blocks tcat align tlrc volreg mask blur scale regress \
          -blip_reverse_dset "$data_folder"/sub-"$subject_id"/ses-002/fmap/*acq-tonotopy*.nii.gz \
          -tcat_remove_first_trs 8 \
          -radial_correlate_blocks tcat volreg \
          -copy_anat "$data_folder/derivatives/sub-${subject_id}/SSwarper/anatSS.sub-${subject_id}.nii.gz" \
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
          -regress_bandpass 0.01 1 \
          -regress_stim_times "$stim_folder"/task-tonotopy_condition-*Hz.1D \
          -regress_basis 'BLOCK(6.4, 1)' \
          -regress_stim_labels 0175Hz 0247Hz 0350Hz 0495Hz 0700Hz 0990Hz 1400Hz 1980Hz 2800Hz 3960Hz \
          -regress_opts_3dD -local_times \
              -gltsym 'SYM: -0175Hz -0247Hz -0350Hz -0495Hz +0990Hz +1400Hz +1980Hz +2800Hz +3960Hz' \
              -glt_label 1 hiVsLo \
          -regress_reml_exec \
          -remove_preproc_files \
          -html_review_style pythonic

      tcsh -xef "$script_path.$timestamp" 2>&1 | tee "$output_path.$timestamp"

      # Rename files with more meaningful names
      3dcalc -a "$results_path.$timestamp"/pb02."$subject_id".r01.volreg+orig.BRIK -expr 'a' -prefix "$results_path.$timestamp"/tono_down1_ver1
      3dcalc -a "$results_path.$timestamp"/pb02."$subject_id".r02.volreg+orig.BRIK -expr 'a' -prefix "$results_path.$timestamp"/tono_up1_ver1

      3dcalc -a "$results_path.$timestamp"/vr_base+orig. -expr 'a' -prefix "$results_path.$timestamp"/vr_base.nii.gz

      # This tells bbregister to create a data file with all the registration parameters needed to align the T2 image to the associated T1 image.
      bbregister --s "$subject_id" --mov "$results_path.$timestamp"/vr_base.nii.gz --reg "$output_path.$timestamp"/"$subject_id"-tono-register.dat --T2

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
