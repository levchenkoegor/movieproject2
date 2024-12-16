import os
import json
import sys

def add_intended_for_field(base_dir, subject, session):
    # Construct the subject and session identifiers
    subject = f"sub-{subject}"
    session = f"ses-{session}"

    # Define the field map directory
    fmap_dir = os.path.join(base_dir, subject, session, 'fmap')

    # Define the intended files directory
    intended_dir = os.path.join(session, 'func')

    if str(session) == "ses-001":
    # Loop over each JSON file in the field map directory
        for filename in os.listdir(fmap_dir):
            if filename.endswith('.json'):
                json_path = os.path.join(fmap_dir, filename)

                # Determine the run number from the filename
                run_number = filename.split('_')[4].split('-')[1]

                # Create the intended file path
                intended_file = f"{intended_dir}/{subject}_{session}_task-backtothefuture_run-{run_number}_bold.nii.gz"

                if subject == 'sub-24' and run_number == '001':
                    intended_file = [f"{intended_dir}/{subject}_{session}_task-backtothefuture_acq-beforepause_run-{run_number}_bold.nii.gz",
                                     f"{intended_dir}/{subject}_{session}_task-backtothefuture_acq-afterpause_run-{run_number}_bold.nii.gz"]
                elif subject == 'sub-36' and run_number == '001':
                    intended_file = [f"{intended_dir}/{subject}_{session}_task-backtothefuture_acq-beforepause_run-{run_number}_bold.nii.gz",
                                     f"{intended_dir}/{subject}_{session}_task-backtothefuture_acq-afterpause_run-{run_number}_bold.nii.gz"]

                # Read the existing JSON data
                with open(json_path, 'r') as file:
                    data = json.load(file)

                # Add the IntendedFor field
                if isinstance(intended_file, list):
                    data['IntendedFor'] = intended_file  # It's already a list
                else:
                    data['IntendedFor'] = [intended_file]  # Wrap it in a list

                # Write the updated JSON data back to the file
                with open(json_path, 'w') as file:
                    json.dump(data, file, indent=4)

        print(f"IntendedFor fields added successfully for {subject} {session}!")

    elif session == "ses-002":
        # Loop over each JSON file in the field map directory
        for filename in os.listdir(fmap_dir):
            if filename.endswith('.json'):
                json_path = os.path.join(fmap_dir, filename)

                # Determine the acquisition type from the filename
                acq_type = filename.split('_')[2].split('-')[1]

                # Find matching functional files
                intended_files = []
                for func_filename in os.listdir(os.path.join(base_dir, subject, intended_dir)):
                    if func_filename.endswith('_bold.nii.gz') and f"task-{acq_type}" in func_filename:
                        intended_files.append(f"{intended_dir}/{func_filename}")

                # Read the existing JSON data
                with open(json_path, 'r') as file:
                    data = json.load(file)

                # Add the IntendedFor field
                data['IntendedFor'] = intended_files

                # Write the updated JSON data back to the file
                with open(json_path, 'w') as file:
                    json.dump(data, file, indent=4)

        print(f"IntendedFor fields added successfully for {subject} {session}!")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python script.py <base_dir> <subject> <session>")
        sys.exit(1)

    base_dir = sys.argv[1]
    subject = sys.argv[2]
    session = sys.argv[3]

    add_intended_for_field(base_dir, subject, session)
