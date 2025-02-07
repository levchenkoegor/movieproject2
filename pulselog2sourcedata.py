from pathlib import Path
import shutil

# Define the project paths
project_path = Path("/data/elevchenko/MovieProject2")
raw_data_path = project_path / "raw_data"
bids_data_path = project_path / "bids_data/sourcedata"

# Define exceptions for specific subjects and sessions where the first run was paused
paused_files_exceptions = {
    ('24', '240801EA'): ["beforepause", "afterpause"],
    ('36', '240709PR'): ["beforepause", "afterpause"]
}

# Iterate over each subject folder in raw_data
for subject_folder in sorted(raw_data_path.glob("sub-*")):
    subject_id = subject_folder.name.split("-")[1]

    if subject_id in ['04', '15']:
        continue

    # Gather and sort session folders by date (from session folder name)
    session_folders = sorted(subject_folder.glob("sess-*"), key=lambda x: x.name[5:11])  # Sort by date part

    # Assign BIDS session IDs based on sorted order
    for idx, session_folder in enumerate(session_folders, start=1):
        session_bids_id = f"{idx:03d}"  # ses-001 for first, ses-002 for second

        # Extract the date and initials to construct the correct physio folder name
        physio_folder_name = f"Physio{session_folder.name[5:]}"
        physio_folder = session_folder / physio_folder_name

        # Check if the physio folder exists for this session
        if not physio_folder.exists():
            print(f"Physio folder not found for subject {subject_id}, session {session_bids_id}. Skipping...")
            continue

        # Define the output path in BIDS format
        output_folder = bids_data_path / f"sub-{subject_id}" / f"ses-{session_bids_id}" / "func"
        output_folder.mkdir(parents=True, exist_ok=True)

        # Search for PULS.log files > 9.5 MB and > 1 MB for session 1 and 2 respectively
        if idx == 1: # session-1
            puls_files = sorted([p for p in physio_folder.glob("*_PULS.log") if p.stat().st_size > 3 * 1024 * 1024])
            if len(puls_files) != 3:
                print(
                    f"Warning for subject {subject_id}, "
                    f"session {session_bids_id}: Found {len(puls_files)} "
                    f"relevant PULS files. Expected 3 (3 BTF runs)")
        elif idx == 2: # session-2
            puls_files = sorted([p for p in physio_folder.glob("*_PULS.log") if p.stat().st_size > 1 * 1024 * 1024])
            if len(puls_files) != 5:
                print(
                    f"Warning for subject {subject_id}, "
                    f"session {session_bids_id}: Found {len(puls_files)} "
                    f"relevant PULS files. Expected 5 (3 pRF + 2 tono).")

        # Process each relevant PULS file
        run_id_btf = 1
        run_id_prf = 1
        run_id_tono = 1
        run_pause_i = 0

        for puls_file in puls_files:
            if any(substring in str(puls_file) for substring in ['c14b6aac-4b5b-4401-8c44-b4b2b756541d',
                                                                 'e25f21eb-ed3f-462a-b184-2ef92e6e15cf']):
                continue

            # Extract unique identifier from PULS filename to find matching Info file
            unique_id = puls_file.stem.split("_")[3]

            # Search for the matching Info file in the same directory
            matching_info_file = next((f for f in physio_folder.glob(f"*{unique_id}*_Info.log")), None)

            if matching_info_file:

                # Check for paused run exceptions
                if (subject_id, session_folder.name[5:]) in paused_files_exceptions and run_pause_i < 2:
                    # Handle the paused run exception by adding `acq-beforepause` or `acq-afterpause`
                    acq_labels = paused_files_exceptions[(subject_id, session_folder.name[5:])]
                    puls_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_task-backtothefuture_acq-{acq_labels[run_pause_i]}_run-001_physioPULS.tsv"
                    info_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_task-backtothefuture_acq-{acq_labels[run_pause_i]}_run-001_physioInfo.tsv"
                    run_pause_i += 1

                    if run_pause_i == 2:
                        run_id_btf += 1

                # Define new filenames for BIDS format
                elif idx == 1:
                    puls_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_run-{run_id_btf:03d}_task-backtothefuture_physioPULS.tsv"
                    info_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_run-{run_id_btf:03d}_task-backtothefuture_physioInfo.tsv"
                    run_id_btf += 1
                elif idx == 2:
                    if (puls_file.stat().st_size > 2 * 1024 * 1024) and (puls_file.stat().st_size < 2.5 * 1024 * 1024): # pRF
                        puls_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_run-{run_id_prf:03d}_task-retinotopy_physioPULS.tsv"
                        info_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_run-{run_id_prf:03d}_task-retinotopy_physioInfo.tsv"
                        run_id_prf += 1
                    elif (puls_file.stat().st_size > 1.5 * 1024 * 1024) and (puls_file.stat().st_size < 2 * 1024 * 1024): # tonotopy
                        puls_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_run-{run_id_tono:03d}_task-tonotopy_physioPULS.tsv"
                        info_bids_name = f"sub-{subject_id}_ses-{session_bids_id}_run-{run_id_tono:03d}_task-tonotopy_physioInfo.tsv"
                        run_id_tono += 1
                    else:
                        print(f"Double-check the {physio_folder_name}. Something is missing..."
                              f"")
                # Copy and rename files to the BIDS directory
                shutil.copy(puls_file, output_folder / puls_bids_name)
                shutil.copy(matching_info_file, output_folder / info_bids_name)

                print(f"Copied {puls_file.name} to {puls_bids_name}")
                print(f"Copied {matching_info_file.name} to {info_bids_name}")

            else:
                print(
                    f"Warning for subject {subject_id}, session {session_bids_id}: No matching Info file found for {puls_file.name}")
