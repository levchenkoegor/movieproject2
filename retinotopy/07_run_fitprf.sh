#!/bin/bash
# Run it from retinotopy/ folder

export fs_folder=/egor2/egor/MovieProject2/bids_data/derivatives/freesurfer

# Define list of subjects
# subjects=$(ls -d $fs_folder/sub-* | awk -F'/' '{print $NF}' | sed 's/sub-//' | sort -n)
# subjects=("sub-01" "sub-02" "sub-03" "sub-04" "sub-05" "sub-06") # DONE
# subjects=("sub-07" "sub-09" "sub-10")
subjects=("sub-11" "sub-12" "sub-13" "sub-14" "sub-16" "sub-17")

# Define full path to analysis folder containing run_pRF_V7.m
ANALYSIS_PATH="/egor2/egor/MovieProject2/analysis/retinotopy"

# Function to run pRF for one subject
run_fitprf() {
  subj=$1
  echo "Running subject $subj..."
matlab -nodisplay -nosplash -nodesktop -r "try, disp('Starting $subj'); run_pRF_V7('$subj'); disp('Completed $subj'); exit(0); catch ME, disp(getReport(ME)); exit(1); end;" \
  > "../logs/${subj}_fitprf.log" 2>&1
  echo "Finished subject $subj!"
}

export -f run_fitprf

# Run in parallel (up to 3 processes at a time)
parallel --joblog ../logs/07_run_fitprf_joblog.txt -j 3 run_fitprf ::: "${subjects[@]}"

