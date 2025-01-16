#!/bin/bash

# This script was developed and tested under bash 5.0.17(1)-release
echo "The script was developed and tested under bash 5.0.17(1)-release"
echo -e "Your version of bash is $BASH_VERSION\n"

# Heudiconv
echo "The script was developed and tested under heudiconv 1.3.0"
heudiconv_version=$(docker run --rm nipy/heudiconv:latest heudiconv --version)


### Step 1
## Create heuristics.py and all dicominfo.tsv files for each subject with heudiconv tool
## Read more about it here: https://github.com/nipy/heudiconv
## Useful tutorial to understand heudiconv: https://reproducibility.stanford.edu/bids-tutorial-series-part-2a/
## Run from /MovieProject2/ folder

# Define the path to the project
project_path="/data/elevchenko/MovieProject2"
subjects="01 02 03 04 05 06 07 08 09 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25 26 27 29 30 31 32 33 34 35 36 37 38 39 40 42 43 44"
# Excluded: 15 (didn't feel well), 28 & 41 - never came

for subj_id in $subjects; do
  subj_dir="${project_path}/raw_data/sub-$subj_id/"

  # Check if the subject directory exists
  if [ -d "$subj_dir" ]; then
    sess_ids=$(ls "$subj_dir")

    # Main loop for session processing
    for full_sess_id in $sess_ids; do
      sess_id="${full_sess_id:5}"
      echo "$sess_id"

      # main Docker run
      docker run --rm -v "${project_path}:/base" nipy/heudiconv:latest \
        -d "/base/raw_data/sub-{subject}/sess-{session}/*/*.dcm" \
        -o "/base/analysis/heudiconv_first_outputs/" \
        -f convertall -s "$subj_id" -ss "$sess_id" \
        -c none

    done
  else
    echo "Directory $subj_dir does not exist."
  fi

done


## The output gives you a bunch of files: filegroup.json, heuristic.py, {subject}.auto.txt, dicominfo.tsv, {subject}.edit.txt
## Review the dicominfo.tsv table and create/edit heuristic.py file. Heuristic file gonna convert all raw dicom files to BIDS-valid format.
## Take one heuristic.py and edit it


### Step 2
## Run actual conversion to BIDS

for subj_id in $subjects; do
  subj_dir="${project_path}/raw_data/sub-$subj_id/"
  sess_i=1

  # Check if the subject directory exists
  if [ -d "$subj_dir" ]; then
    sess_ids=$(ls "$subj_dir")

    for full_sess_id in $sess_ids; do
      sess_id="${full_sess_id:5}"

      docker run --rm -v ${PWD}:/base nipy/heudiconv:latest \
       -d /base/raw_data/sub-{subject}/sess-${sess_id}/*/*.dcm \
       -o /base/bids_data/ \
       -f /base/analysis/heuristic_sess0"${sess_i}".py \
       -s "$subj_id" -ss "00${sess_i}" \
       -c dcm2niix -b

      sess_i=$((sess_i+1))
   done
  else
    echo "Directory $subj_dir does not exist."
  fi
done

echo "Changing the owner of bids_data folder from root to elevchenko and grant permissions to edit files..."
chown -R elevchenko:elevchenko "${project_path}/bids_data"
chmod 777 -R "${project_path}/bids_data"


### Step 3
## Add 'IntendedFor' field for phase reverse encoding files

for subject in $subjects; do
    for session in 001 002; do
        python analysis/add_intendedfor_field.py "${project_path}/bids_data" "$subject" "$session"
    done
done


### Step 4
## Put raw eye-tracker data (backtothefuture and pRF tasks) to sourcedata/ folder

for subject in $subjects; do

    # Skip bad subject
    if [[ "$subject" == "29" ]]; then
        continue
    fi

    # Get the list of session folders for the subject
    session_folders=($(ls -d "${project_path}"/raw_data/sub-"${subject}"/sess-* 2>/dev/null | sort))

    # Check the number of session folders found
    session_count=${#session_folders[@]}

    for session_num in 001 002; do

        if [[ "$session_num" == "001" || $session_count -eq 1 ]]; then
            # Use the first session folder if theres only one or if we're processing session 001
            session_folder="${session_folders[0]}"
        elif [[ "$session_num" == "002" && $session_count -eq 2 ]]; then
            # Use the second session folder if we're processing session 002 and it exists
            session_folder="${session_folders[1]}"
        else
            # If session 002 doesn't exist, skip
            echo "No session ${session_num} found for subject ${subject}. Skipping..."
            continue
        fi

        # Extract session name (e.g., sess-241123EL)
        session_name=$(basename "$session_folder")

        # Define the destination path in BIDS format
        dest_path="${project_path}/bids_data/sourcedata/sub-${subject}/ses-${session_num}/func"

        # Create the destination directory if it doesn't exist
        mkdir -p "$dest_path"

        # Find all .edf files in the session folder
        if [[ "$session_num" == "001" ]]; then
            edf_files=($(ls "$session_folder"/*_r*.edf | sort -V))
        else
            edf_files=($(ls "$session_folder"/*pRF*.edf | grep -v 'Calib' | sort -V))
        fi

        # Check the number of files found
        file_count=${#edf_files[@]}
        if [[ $file_count -ne 3 ]]; then
            echo "Warning: Found $file_count .edf files for sub-${subject}, ${session_name}. Expected 3. Please inspect the data!"
        fi

        # Find all .edf files in the earliest session folder and compress them
        for edf_file in "${edf_files[@]}"; do

            # Skip bad files
            if [[ "$edf_file" == *"06-Mar-2024_12_16_41"* || "$edf_file" == *"27-Mar-2024_13_27_44"* ]]; then
                continue
           fi

            # Extract the run number from the filename
            if [[ "$edf_file" == *"_pRF_"* ]]; then
                # For pRF cases, extract the second digit after _pRF_
                raw_run_number=$(echo "$edf_file" | grep -oP '_pRF_[0-9]+_[0-9]+' | cut -d'_' -f4)
            else
                # For run- or _r cases, extract the first digit after run- or _r
                raw_run_number=$(echo "$edf_file" | grep -oP '(?:run-|_r)\K[0-9]+')
            fi

            # Handle the exception with the typo
            if [[ $raw_run_number -eq 26 ]]; then
                raw_run_number=2
            fi

            # Ensure the raw run number is properly mapped to BIDS format run number (001, 002, 003)
            run_id=$(printf "%03d" "$raw_run_number")

            # Define task name based on session
            if [[ "$session_num" == "001" ]]; then
                task_name="backtothefuture"
            else
                task_name="pRF"
            fi

            # Define the output file path
            output_edf="$dest_path/sub-${subject}_ses-${session_num}_run-${run_id}_task-${task_name}_eyelinkraw.edf"
            output_asc="$dest_path/sub-${subject}_ses-${session_num}_run-${run_id}_task-${task_name}_eyelinkraw.asc"

            # Check if the file already exists
            if [[ -f "$output_edf" ]]; then
                echo "File already exists: $output_edf. Overwriting... (made on purpose!)"
            fi
            if [[ -f "$output_asc" ]]; then
                echo "File already exists: $output_asc. Overwriting... (made on purpose!)"
            fi

            # Rename and compress each .edf file with the appropriate run number
            echo "Copying and gziping raw eyetracker EDF data for sub-${subject}, ${session_name}, task-${task_name}, run-${run_id}..."
            gzip -c "$edf_file" > "${output_edf}.gz"

            # Convert to ASCII using eye-link developers kit and compress
            edf2asc "$edf_file" "$output_asc"
            gzip -f "$output_asc"

        done
    done
done



### Step 5
## Save behavioural summary data to derivatives
# Activate conda environment with all needed packages installed
source "$project_path"/utils/miniconda3/bin/activate
conda activate movieproject2

# Tonotopy
python "$project_path"/analysis/tonotopy_behaviour.py
# pRF
python "$project_path"/analysis/pRF_behaviour.py


### Step 6
## Deface all anatomical scans

# Setup FSL
export FSLDIR=/tools/fsl
. ${FSLDIR}/etc/fslconf/fsl.sh
export PATH=${FSLDIR}/bin:${PATH}

# Find and deface all T1w anatomical scans
find "$project_path"/bids_data/ -type f -name "*_T1w.nii.gz" | sort | while read -r anat_file; do
    # Display the current file being processed
    echo "Processing: $anat_file"

    # Run pydeface and overwrite the original file
    pydeface "$anat_file" --outfile "$anat_file" --force

    # Indicate completion of current file
    echo "Defacing complete for: $anat_file"
done
echo "All anatomical scans have been defaced."


### Step 7
# Physio data
python "$project_path"/analysis/pulselog2sourcedata.py


echo "Changing the owner of bids_data folder from root to elevchenko and grant permissions to edit files..."
chown -R elevchenko:elevchenko "${project_path}/bids_data"
chmod 777 -R "${project_path}/bids_data"


### Step 8
## Check if the folder is BIDS valid

# BIDS validator
bidsvalidator_version=$(docker run -ti --rm bids/validator --version)

docker run --rm -v "${project_path}/bids_data":/data:ro bids/validator /data
