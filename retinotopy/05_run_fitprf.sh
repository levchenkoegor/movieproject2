#!/bin/bash
# Run it from retinotopy/ folder

# Define list of subjects
subjects=("01" "02")

# Define full path to analysis folder containing run_pRF_V7.m
ANALYSIS_PATH="/egor2/egor/MovieProject2/analysis/retinotopy"

# Function to run pRF for one subject
run_fitprf() {
  subj=$1
  echo "Running subject $subj..."

  matlab -nodisplay -nosplash -nodesktop -r "try, run_pRF_V7('$subj'); catch ME; disp(getReport(ME)); exit(1); end; exit" \
    > "../logs/${subj}_fitprf.log" 2>&1
}

export -f run_fitprf

# Run in parallel (up to 4 processes at a time)
parallel -j 4 run_fitprf ::: "${subjects[@]}"

