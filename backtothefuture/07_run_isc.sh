#!/bin/bash

# Paths and Parameters
data_dir="/egor2/egor/MovieProject2/bids_data/derivatives"
output_dir="$data_dir/group_analysis/backtothefuture/isc"
isc_dir="$output_dir/ISC_maps"

# Create necessary directories
mkdir -p "$isc_dir"

# Detect subjects automatically (skip 01, 02, 03, 10, 24 and 36 since potential alignment issues)
subjects=()
for s in $(ls "$data_dir" | grep "sub-"); do
  if [[ "$s" != "sub-01" && "$s" != "sub-02" && "$s" != "sub-03" && "$s" != "sub-10"  && "$s" != "sub-24" && "$s" != "sub-36" ]]; then
    subjects+=("$s")
  fi
done

# Check and prepare DataTable
data_table="$output_dir/DataTable_ISC.txt"
echo -e "Subj1\tSubj2\tgrp\tInputFile" > "$data_table"

# Function to find the correct 'sub-{ID}.results' folder dynamically
find_results_folder() {
  subj=$1
  results_path=$(ls -d "${data_dir}/${subj}/backtothefuture/${subj}.results."* 2>/dev/null | head -n 1)

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
  s1_id=$(echo "$s1" | sed 's/sub-//')
  s2_id=$(echo "$s2" | sed 's/sub-//')

  results_s1=$(find_results_folder "$s1")
  results_s2=$(find_results_folder "$s2")

  if [[ $? -ne 0 || -z "$results_s1" || -z "$results_s2" ]]; then
    echo "Skipping ISC calculation for $s1 and $s2 due to missing results folders."
    return
  fi

  isc_output="$isc_dir/ISC_${s1}_${s2}.nii.gz"
  s1_file="${results_s1}/all_runs.${s1_id}+tlrc.BRIK.gz"
  s2_file="${results_s2}/all_runs.${s2_id}+tlrc.BRIK.gz"
  s1_mask="${results_s1}/full_mask.${s1_id}+tlrc.BRIK.gz"

  if [[ -f "$s1_file" && -f "$s2_file" && -f "$s1_mask" ]]; then
    if [[ ! -f "$isc_output" ]]; then
      echo "Running 3dTcorrelate for $s1 and $s2"
      3dTcorrelate -pearson -polort -1 -Fisher \
        -prefix $isc_output \
        $s1_file'[0..$]' $s2_file'[0..$]'
    fi
    echo -e "$s1\t$s2\t1\t$isc_output" >> "$data_table"
  else
    echo "Missing files for $s1 or $s2. Skipping pair."
  fi
}

# Run ISC calculations for unique subject pairs
for ((i = 0; i < ${#subjects[@]}; i++)); do
  for ((j = i + 1; j < ${#subjects[@]}; j++)); do
    isc_calculation "${subjects[$i]}" "${subjects[$j]}"
  done
done

# Group-level ISC analysis
3dISC -prefix "$output_dir"/ISC_group \
  -jobs 8 \
  -model '1+(1|Subj1)+(1|Subj2)' \
  -mask "$output_dir"/average_T1w_mask.nii.gz \
  -dataTable @$data_table

# Convert to nii format
3dAFNItoNIFTI -prefix "$output_dir"/ISC_group.nii.gz "$output_dir"/ISC_group+tlrc

echo "ISC analysis complete. Results saved to $output_dir"
