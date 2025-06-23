#!/bin/bash

# Paths
export data_folder=/egor2/egor/MovieProject2/bids_data
export stim_folder=/egor2/egor/MovieProject2/stimuli
export fs_folder=/egor2/egor/MovieProject2/bids_data/derivatives/freesurfer

# Setup freesurfer and directories
export FREESURFER_HOME=/tools/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
export SUBJECTS_DIR=/egor2/egor/MovieProject2/bids_data/derivatives/freesurfer

# Maximum number of parallel jobs nad threads
max_jobs=8
export OMP_NUM_THREADS=3

# Subjects with mincost > 0.45
subjects="01 07 20 21 25 44"
echo "The list of subjects to be preprocessed: ${subjects[@]}"

# Run AFNI
for subject_id in $subjects; do

    (
      # Define paths for easier files manipulations
      echo "Processing subject $subject_id"
      subject_folder="$data_folder/derivatives/sub-$subject_id/retinotopy"
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
      afni_proc.py -subj_id "$subject_id" \
          -script "$script_path.$timestamp" \
          -out_dir "$results_path.$timestamp" \
          -dsets "$data_folder"/sub-"$subject_id"/ses-002/func/*task-retinotopy_run-001_bold*.nii.gz \
                 "$data_folder"/sub-"$subject_id"/ses-002/func/*task-retinotopy_run-002_bold*.nii.gz \
                 "$data_folder"/sub-"$subject_id"/ses-002/func/*task-retinotopy_run-003_bold*.nii.gz \
          -blocks tcat volreg scale \
          -blip_reverse_dset "$data_folder"/sub-"$subject_id"/ses-002/fmap/*acq-retinotopy*.nii.gz \
          -tcat_remove_first_trs 8 \
          -radial_correlate_blocks tcat volreg \
          -copy_anat "$data_folder/derivatives/sub-${subject_id}/SSwarper/anatSS.sub-${subject_id}.nii.gz" \
          -volreg_base_dset "$data_folder"/sub-"$subject_id"/ses-002/func/*task-retinotopy_run-001_sbref.nii.gz \
          -volreg_post_vr_allin yes \
          -volreg_opts_vr -twopass -twodup -maxdisp1D mm'.r$run' \
          -volreg_compute_tsnr yes \
          -html_review_style pythonic

      tcsh -xef "$script_path.$timestamp" 2>&1 | tee "$output_path.$timestamp"

      # Convert BRIK to nifti
      3dAFNItoNIFTI -prefix "$results_path.$timestamp"/vr_base_external+orig.nii.gz "$results_path.$timestamp"/vr_base_external+orig.BRIK

      # This tells bbregister to create a data file with all the registration parameters needed to align the T2 image to the associated T1 image
      bbregister --s sub-"$subject_id" --mov "$results_path.$timestamp"/vr_base_external+orig.nii.gz --reg "$results_path.$timestamp"/"$subject_id"-register.dat --T2

      # mri_vol2surf
      runs="01 02 03"
      for run in $runs; do
        # Convert pb02* AFNI to NIFTI format
        3dAFNItoNIFTI -prefix "$results_path.$timestamp"/pb02.${subject_id}.r${run}.volreg+orig.nii.gz "$results_path.$timestamp"/pb02.${subject_id}.r${run}.volreg+orig.BRIK

        mri_vol2surf --mov "$results_path.$timestamp"/pb02.${subject_id}.r${run}.volreg+orig.nii.gz --reg "$results_path.$timestamp"/"$subject_id"-register.dat --trgsubject sub-"$subject_id" --hemi rh --o "$results_path.$timestamp"/vol2surf_rh_sub-${subject_id}_run-${run}.mgh --projfrac 0.5 --surf-fwhm 3
        mri_vol2surf --mov "$results_path.$timestamp"/pb02.${subject_id}.r${run}.volreg+orig.nii.gz --reg "$results_path.$timestamp"/"$subject_id"-register.dat --trgsubject sub-"$subject_id" --hemi lh --o "$results_path.$timestamp"/vol2surf_lh_sub-${subject_id}_run-${run}.mgh --projfrac 0.5 --surf-fwhm 3
      done

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
