#!/bin/bash

# Paths and Parameters
data_dir="/data/elevchenko/MovieProject2/bids_data/derivatives"
output_dir="$data_dir/group_analysis/backtothefuture/isc"
mask_dir="$output_dir/masks"
isc_dir="$output_dir/ISC_maps"

# Create necessary directories
mkdir -p $mask_dir $isc_dir

# Detect subjects automatically
#subjects=($(ls $data_dir | grep "sub-"))
subjects=("sub-07" "sub-08")

# Check and prepare DataTable
data_table="$output_dir/DataTable_ISC.txt"
echo -e "Subj1\tSubj2\tgrp\tInputFile" > $data_table

# Function to find the correct 'sub-{ID}.results' folder dynamically
find_results_folder() {
  subj=$1
  results_path=$(ls -d ${data_dir}/${subj}/backtothefuture/${subj}.results.* 2>/dev/null | head -n 1)

  if [[ -z "$results_path" ]]; then
    echo "ERROR: No results folder found for $subj in $data_dir" >&2
    return 1
  fi

  echo "$results_path"
}

# ISC Calculation Function
isc_calculation() {
  s1=$1
  s2=$2
  s1_id=$(echo $s1 | sed 's/sub-//')
  s2_id=$(echo $s2 | sed 's/sub-//')

  results_s1=$(find_results_folder "$s1")
  results_s2=$(find_results_folder "$s2")

  if [[ $? -ne 0 ]]; then
    echo "Skipping ISC calculation for $s1 and $s2 due to missing results folders."
    return
  fi

  isc_output="$isc_dir/ISC_${s1}_${s2}.nii.gz"
  s1_file="${results_s1}/all_runs.${s1_id}+tlrc.BRIK.gz"
  s2_file="${results_s2}/all_runs.${s2_id}+tlrc.BRIK.gz"
  s1_mask="${mask_dir}/${s1}_mask.nii.gz"

  if [[ -f "$s1_file" && -f "$s2_file" && -f "$s1_mask" ]]; then
    if [[ ! -f "$isc_output" ]]; then
      echo "Running 3dTcorrelate for $s1 and $s2"
      3dTcorrelate -pearson -polort -1 -Fisher \
        -mask $s1_mask \
        -prefix $isc_output \
        $s1_file'[0..$]' $s2_file'[0..$]'
    fi
    echo -e "$s1\t$s2\t1\t$isc_output" >> $data_table
  else
    echo "Missing files for $s1 or $s2. Skipping pair."
  fi
}

# Create group-level mask
cd $mask_dir
3dMean -prefix "$output_dir/average_T1w_mask.nii.gz" full_mask.*+tlrc*.HEAD

# Run ISC calculations for unique subject pairs
for ((i = 0; i < ${#subjects[@]}; i++)); do
  for ((j = i + 1; j < ${#subjects[@]}; j++)); do
    s1=${subjects[$i]}
    s2=${subjects[$j]}
    isc_calculation "$s1" "$s2"
  done
done

# Group-level ISC analysis
cd $output_dir
3dISC -prefix ISC_group -jobs 8 \
  -model 'grp+(1|Subj1)+(1|Subj2)' -qVars grp \
  -mask "$output_dir/average_T1w_mask.nii.gz" \
  -dataTable @$data_table

echo "ISC analysis complete. Results saved to $output_dir."
