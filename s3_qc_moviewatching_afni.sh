#!/bin/bash

# Paths
export data_folder=/data/elevchenko/MovieProject2/bids_data
export stim_folder=/data/elevchenko/MovieProject2/stimuli

# Maximum number of parallel jobs
max_jobs=8

subjects="01 02 03 04 05 06 07 08 09 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44"

# Run AFNI
# Done: 01 02 03 04 05 06 10 24 36

for subject_id in 07 08 09 10 11 12 13 14; do #$subjects; do

    (
      # Start timing
      start_time=$(date +%s)

      # Paths for outputs
      echo "Processing subject-$subject_id"
      subject_folder="$data_folder"/derivatives/sub-"$subject_id"/movie
      script_path="$subject_folder"/proc.sub-"$subject_id"
      output_path="$subject_folder"/output.proc.sub-"$subject_id"
      results_path="$subject_folder"/sub-"$subject_id".results

      # Create target directory if it does not exist
      if [ ! -d "$subject_folder" ]; then
          mkdir -p "$subject_folder"
          echo "Created directory $subject_folder"
      fi

      # Default input paths
      dsets=(
          "$data_folder/sub-${subject_id}/ses-001/func/sub-${subject_id}_ses-001_task-backtothefuture_run-001_bold.nii.gz"
          "$data_folder/sub-${subject_id}/ses-001/func/sub-${subject_id}_ses-001_task-backtothefuture_run-002_bold.nii.gz"
          "$data_folder/sub-${subject_id}/ses-001/func/sub-${subject_id}_ses-001_task-backtothefuture_run-003_bold.nii.gz"
      )
      anat_path="$data_folder/sub-${subject_id}/ses-001/anat/sub-${subject_id}_ses-001_T1w.nii.gz"
      stim_file="$stim_folder/task-backtothefuture_condition-speech_run-all.1D"
      n_trs_remove="8 16 16"

      # Adjustments for non-standard subjects:
      # 01 (run2 stopped in the end)
      # 02 (incorrect cut for movie files)
      # 03 (run1 stopped in the end)
      # 10 (had to stop run3 15 mins before the end)
      # 24 (movie paused during run1: 1025 + 351 TRs)
      # 36 (movie paused during run1: 400 + 978 TRs) *weird number of TRs (2 more than expected)
      if [ "$subject_id" == "01" ]; then
          stim_file="$stim_folder/task-backtothefuture_condition-speech_run-all_subs-01.1D"
      elif [ "$subject_id" == "02" ]; then
          stim_file="$stim_folder/task-backtothefuture_condition-speech_run-all_subs-02.1D"
      elif [ "$subject_id" == "03" ]; then
          stim_file="$stim_folder/task-backtothefuture_condition-speech_run-all_subs-03.1D"
      elif [ "$subject_id" == "10" ]; then
          anat_path="$data_folder/sub-${subject_id}/ses-002/anat/sub-${subject_id}_ses-002_acq-highres_T1w.nii.gz"
      elif [ "$subject_id" == "24" ]; then
          dsets=(
              "$data_folder/sub-24/ses-001/func/sub-24_ses-001_task-backtothefuture_acq-beforepause_run-001_bold.nii.gz"
              "$data_folder/sub-24/ses-001/func/sub-24_ses-001_task-backtothefuture_acq-afterpause_run-001_bold.nii.gz"
              "$data_folder/sub-24/ses-001/func/sub-24_ses-001_task-backtothefuture_run-002_bold.nii.gz"
              "$data_folder/sub-24/ses-001/func/sub-24_ses-001_task-backtothefuture_run-003_bold.nii.gz"
          )
          n_trs_remove="8 16 16 16"
          stim_file="$stim_folder/task-backtothefuture_condition-speech_run-all_subs-24.1D" # no timestamps for afterpause run
      elif [ "$subject_id" == "36" ]; then # 2 unrecognized TRs (probably more adjustments are needed for a perfect alignment)
          dsets=(
              "$data_folder/sub-36/ses-001/func/sub-36_ses-001_task-backtothefuture_acq-beforepause_run-001_bold.nii.gz"
              "$data_folder/sub-36/ses-001/func/sub-36_ses-001_task-backtothefuture_acq-afterpause_run-001_bold.nii.gz"
              "$data_folder/sub-36/ses-001/func/sub-36_ses-001_task-backtothefuture_run-002_bold.nii.gz"
              "$data_folder/sub-36/ses-001/func/sub-36_ses-001_task-backtothefuture_run-003_bold.nii.gz"
          )
          n_trs_remove="8 16 16 16"
          stim_file="$stim_folder/task-backtothefuture_condition-speech_run-all_subs-36.1D" # no timestamps for afterpause run
      fi

      # Run afni proc py for each run separately
      afni_proc.py \
          -subj_id "$subject_id" \
          -script "$script_path" \
          -out_dir "$results_path" \
          -dsets "${dsets[@]}" \
          -blocks tcat align tlrc volreg scale regress \
          -blip_reverse_dset "$data_folder"/sub-"$subject_id"/ses-001/fmap/sub-"$subject_id"_ses-001_acq-func_dir-PA_run-001_epi.nii.gz \
          -tcat_remove_first_trs $n_trs_remove \
          -radial_correlate_blocks volreg \
          -tlrc_base MNI152_2009_template.nii.gz \
          -copy_anat "$anat_path" \
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
          -regress_opts_3dD -num_stimts 1 -local_times \
              -stim_label 1 Speech \
              -stim_times_AM1 1 "$stim_file" 'dmUBLOCK(1)' \
          -html_review_style pythonic

      tcsh -xef "$script_path" 2>&1 | tee "$output_path"


      # End timing
      end_time=$(date +%s)

      # Calculate elapsed time
      elapsed_time=$((end_time - start_time))
      echo "Processing time for subject $subject_id: ${elapsed_time} seconds"
    ) &

    # Limit the number of parallel jobs
    while [ "$(jobs -r | wc -l)" -ge "$max_jobs" ]; do
        sleep 1
    done
done

# Wait for all background jobs to finish
wait