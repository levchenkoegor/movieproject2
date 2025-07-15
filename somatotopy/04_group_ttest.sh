#!/bin/bash

# Define paths
results_dir="/egor2/egor/MovieProject2/bids_data/derivatives"
output_dir="${results_dir}/group_analysis/somatotopy/group_stats"
mkdir -p "$output_dir"
log_file="${output_dir}/group_ttests_log.txt"
> "$log_file"

nifti_out_dir="${output_dir}/niftis"
mkdir -p "$nifti_out_dir"

# get subjects
subjects=$(find "$results_dir" -maxdepth 2 -type d -name "sub-*" | grep -E "sub-[0-9]+$" | awk -F'/' '{print $NF}' | sed 's/sub-//' | sort -n)
subjects=($subjects)
echo "[INFO] Found subjects: ${subjects[@]}" | tee -a "$log_file"

# main effects — preserve AFNI labels for easier indexing, clean names for output
declare -A main_effect_map=(
  ["LeftFoot#0_Coef"]="LeftFoot"
  ["RightFoot#0_Coef"]="RightFoot"
  ["LeftHand#0_Coef"]="LeftHand"
  ["RightHand#0_Coef"]="RightHand"
  ["LeftFace#0_Coef"]="LeftFace"
  ["RightFace#0_Coef"]="RightFace"
  ["LeftTongue#0_Coef"]="LeftTongue"
  ["RightTongue#0_Coef"]="RightTongue"
)

# contrasts — all AFNI labels are "LeftFootVSRightFoot#N_Coef", but they mean:
contrast_labels=(
  "LeftFootVSRightFoot"
  "LeftHandVSRightHand"
  "LeftFaceVSRightFace"
  "LeftTongueVSRightTongue"
  "FaceVSFoot"
  "FaceVSHand"
  "FaceVSTongue"
  "HandVSFoot"
  "HandVSTongue"
  "FootVSTongue"
)

# Reference stats file for sub-brick index lookup
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

# ttests for main effects
for label in "${!main_effect_map[@]}"; do
  idx="${label2idx[$label]}"
  output_label="${main_effect_map[$label]}"

  if [[ -z "$idx" ]]; then
    echo "[SKIP] $label not found in sub-bricks." | tee -a "$log_file"
    continue
  fi

  echo "[INFO] Running 3dttest++ for main effect: $output_label (sub-brick $idx)" | tee -a "$log_file"

  setA=()
  for subj in "${subjects[@]}"; do
    stat_file=$(find "${results_dir}/sub-${subj}/somatotopy" -name "stats.${subj}_REML+tlrc.HEAD" | head -n 1 | sed 's/\.HEAD$//')
    if [[ -f "${stat_file}.HEAD" && -f "${stat_file}.BRIK.gz" ]]; then
      setA+=("s${subj}" "${stat_file}[${idx}]")
    fi
  done

  3dttest++ \
    -prefix "${output_dir}/group_ttest_${output_label}" \
    -mask "$output_dir/group_mask+tlrc" \
    -setA Group "${setA[@]}" \
    | tee -a "$log_file"

  3dAFNItoNIFTI -prefix "${nifti_out_dir}/group_ttest_${output_label}.nii.gz" "${output_dir}/group_ttest_${output_label}+tlrc"
done

# ttests for contrasts
for idx in "${!contrast_labels[@]}"; do
  afni_label="LeftFootVSRightFoot#${idx}_Coef"  # still use this to extract the index
  output_label="${contrast_labels[$idx]}"  # correct contrast name
  idx_val="${label2idx[$afni_label]}"

  if [[ -z "$idx_val" ]]; then
    echo "[SKIP] Could not find sub-brick for $afni_label" | tee -a "$log_file"
    continue
  fi

  echo "[INFO] Running 3dttest++ for contrast: $output_label (from sub-brick $idx_val)" | tee -a "$log_file"

  setA=()
  for subj in "${subjects[@]}"; do
    stat_file=$(find "${results_dir}/sub-${subj}/somatotopy" -name "stats.${subj}_REML+tlrc.HEAD" | head -n 1 | sed 's/\.HEAD$//')
    if [[ -f "${stat_file}.HEAD" && -f "${stat_file}.BRIK.gz" ]]; then
      setA+=("s${subj}" "${stat_file}[${idx_val}]")
    fi
  done

  3dttest++ \
    -prefix "${output_dir}/group_ttest_${output_label}" \
    -mask "$output_dir/group_mask+tlrc" \
    -setA Group "${setA[@]}" \
    | tee -a "$log_file"

  3dAFNItoNIFTI -prefix "${nifti_out_dir}/group_ttest_${output_label}.nii.gz" "${output_dir}/group_ttest_${output_label}+tlrc"
done

# symlink mni template
template_src="${results_dir}/sub-01/backtothefuture/sub-01.results.20250211_214642/MNI152_2009_template_SSW.nii.gz"
template_dest="${output_dir}/MNI152_2009_template_SSW.nii.gz"
if [[ ! -e "$template_dest" ]]; then
  ln -s "$template_src" "$template_dest"
  echo "[INFO] Symlink created: $template_dest" | tee -a "$log_file"
else
  echo "[INFO] Symlink already exists: $template_dest" | tee -a "$log_file"
fi

echo "[DONE] All group tests and NIfTI conversions complete." | tee -a "$log_file"