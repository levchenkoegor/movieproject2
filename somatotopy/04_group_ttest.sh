#!/bin/bash

# Define paths
results_dir="/egor2/egor/MovieProject2/bids_data/derivatives"
output_dir="${results_dir}/group_analysis/somatotopy/group_stats"
mkdir -p "$output_dir"
log_file="${output_dir}/group_ttests_log.txt"
> "$log_file"  # clear previous log

# Get subject IDs with somatotopy results
subjects=$(find "$results_dir" -maxdepth 2 -type d -name "sub-*" | grep -E "sub-[0-9]+$" | awk -F'/' '{print $NF}' | sed 's/sub-//' | sort -n)
subjects=($subjects)
echo "[INFO] Found subjects: ${subjects[@]}" | tee -a "$log_file"

# Define conditions and contrasts
# Not sure why but all glt labels are the same: LeftFootVSRightFoot for all contrasts
# Contrasts sub-bricks actually contain:
#1 'LeftFootVSRightFoot'
#2 'LeftHandVSRightHand'
#3 'LeftFaceVSRightFace'
#4 'LeftTongueVSRightTongue'
#5 'FaceVSFoot'
#6 'FaceVSHand'
#7 'FaceVSTongue'
#8 'HandVSFoot'
#9 'HandVSTongue'
#10 'FootVSTongue'
labels=("LeftFoot#0_Coef" "RightFoot#0_Coef" "LeftHand#0_Coef" "RightHand#0_Coef" "LeftFace#0_Coef" "RightFace#0_Coef" "LeftTongue#0_Coef" "RightTongue#0_Coef"
        "LeftFootVSRightFoot#0_Coef" "LeftFootVSRightFoot#1_Coef" "LeftFootVSRightFoot#2_Coef" "LeftFootVSRightFoot#3_Coef"
        "LeftFootVSRightFoot#4_Coef" "LeftFootVSRightFoot#5_Coef" "LeftFootVSRightFoot#6_Coef" "LeftFootVSRightFoot#7_Coef"
        "LeftFootVSRightFoot#8_Coef" "LeftFootVSRightFoot#9_Coef")

# Get sub-brick indices from a reference subject (sub-01)
ref_subj="01"
ref_stats_file=$(find "${results_dir}/sub-${ref_subj}/somatotopy" -name "stats.${ref_subj}_REML+tlrc.HEAD" | head -n 1)
declare -A label2idx

echo "[INFO] Parsing sub-brick indices from: $ref_stats_file" | tee -a "$log_file"
while IFS= read -r line; do
  if [[ "$line" =~ Coef ]]; then
    label=$(echo "$line" | grep -oE "'[^']+'" | tr -d "'")
    idx=$(echo "$line" | grep -oE "#[0-9]+" | head -n1 | tr -d '#')
    label2idx["$label"]=$idx
    echo "[PARSED] $label -> $idx" >> "$log_file"
  fi
done < <(3dinfo -verb "$ref_stats_file")

# Creating group mask
3dmask_tool \
  -input $results_dir/sub-*/somatotopy/sub-*.results.*/full_mask.*+tlrc.HEAD \
  -prefix $output_dir/group_mask \
  -frac 0 \
  -overwrite


# Loop over each label and run 3dttest++
for label in "${labels[@]}"; do
  idx="${label2idx[${label}]}"
  if [[ -z "$idx" ]]; then
    echo "[SKIP] $label not found in sub-bricks. Skipping..." | tee -a "$log_file"
    continue
  fi

  setA=()
  for subj in "${subjects[@]}"; do
    stat_file=$(find "${results_dir}/sub-${subj}/somatotopy" -type f -name "stats.${subj}_REML+tlrc.HEAD" | head -n 1 | sed 's/\.HEAD$//')

    if [[ -f "${stat_file}.HEAD" && -f "${stat_file}.BRIK.gz" ]]; then
      setA+=("s${subj}" "${stat_file}[${idx}]")
      subbrick_label=$(3dinfo -label "${stat_file}[${idx}]")
      echo "[SUBJ] sub-${subj} using index $idx -> ${stat_file}[${idx}] = $subbrick_label" >> "$log_file"
   else
      echo "[MISSING] ${stat_file}.HEAD or .BRIK.gz not found for sub-${subj}" | tee -a "$log_file"
    fi
  done

  echo "[INFO] Running 3dttest++ for label: $label (sub-brick #$idx)" | tee -a "$log_file"
  3dttest++ \
    -prefix "${output_dir}/group_ttest_${label}" \
    -mask "$output_dir/group_mask+tlrc" \
    -setA Group "${setA[@]}" \
    | tee -a "$log_file"

done
echo "[DONE] All t-tests complete. Log saved to $log_file"

template_src="/egor2/egor/MovieProject2/bids_data/derivatives/sub-01/backtothefuture/sub-01.results.20250211_214642/MNI152_2009_template_SSW.nii.gz"
template_dest="${output_dir}/MNI152_2009_template_SSW.nii.gz"
if [[ ! -e "$template_dest" ]]; then
  ln -s "$template_src" "$template_dest"
  echo "[INFO] Symlink created: $template_dest" | tee -a "$log_file"
else
  echo "[INFO] Symlink already exists: $template_dest" | tee -a "$log_file"
fi
