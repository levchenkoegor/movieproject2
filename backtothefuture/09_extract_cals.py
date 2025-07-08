import gzip
import shutil
import pandas as pd
from pathlib import Path
from mne.preprocessing.eyetracking import read_eyelink_calibration


root = "/egor2/egor/MovieProject2/bids_data/sourcedata"
results = []

for gz_path in sorted(Path(root).rglob("*task-backtothefuture*.asc.gz")):
    gz_path = gz_path.resolve()
    asc_path = gz_path.with_suffix('')  # remove .gz

    # Decompress if needed
    if not asc_path.exists():
        with gzip.open(gz_path, 'rb') as f_in, open(asc_path, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

    # Parse calibration metadata
    try:
        calib_data = read_eyelink_calibration(asc_path,
                                              screen_size=None,
                                              screen_distance=None,
                                              screen_resolution=None)
    except Exception as e:
        print(f"Failed to read {asc_path.name}: {e}")
        continue

    # Extract subject and run info
    parts = gz_path.parts
    subject = parts[parts.index("sourcedata") + 1]  # 'sub-0*'
    run = asc_path.stem.split("_run-")[1][:3]       # '00*'

    # Filter to only the last calibration per eye
    eye_entries = {}
    for calib in calib_data:
        eye = calib['eye']
        eye_entries[eye] = calib  # overwrite; last one wins

    for eye, calib in eye_entries.items():
        avg_error = calib['avg_error']
        max_error = calib['max_error']

        results.append({
            "subject": subject,
            "run": run,
            "eye": eye,
            "avg_error_deg": avg_error,
            "max_error_deg": max_error
        })

    # Remove the temporary uncompressed .asc file
    try:
        asc_path.unlink()
    except Exception as e:
        print(f"Could not remove {asc_path.name}: {e}")

# Convert to DataFrame and save
df = pd.DataFrame(results)
df.to_csv("/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/df_eyelink_calibration_errors.csv", index=False)


# Print some descriptive statistics
def classify_calibration(avg, max_):
    if avg < 1.0 and max_ < 1.5:
        return "GOOD"
    elif avg < 1.5 and max_ < 2.0:
        return "FAIR"
    else:
        return "POOR"

df["quality"] = df.apply(lambda row: classify_calibration(row["avg_error_deg"], row["max_error_deg"]), axis=1)

# Print descriptive stats
mean_avg = df["avg_error_deg"].mean()
std_avg = df["avg_error_deg"].std()
mean_max = df["max_error_deg"].mean()
std_max = df["max_error_deg"].std()

print("\n=== Calibration Error Summary ===")
print(f"Average Error: {mean_avg:.2f}° ± {std_avg:.2f}")
print(f"Maximum Error: {mean_max:.2f}° ± {std_max:.2f}")

# Count quality classes
counts = df["quality"].value_counts().reindex(["GOOD", "FAIR", "POOR"], fill_value=0)
print("\n=== Quality Classification Counts ===")
for label in ["GOOD", "FAIR", "POOR"]:
    print(f"{label}: {counts[label]}")

# Find subjects with POOR calibrations
poor_subjects = df[df["quality"] == "POOR"]["subject"].unique()
print("\n=== Subjects with at least one POOR calibration ===")
if len(poor_subjects) > 0:
    for subj in sorted(poor_subjects):
        print(subj)
else:
    print("None")

df.to_csv("/egor2/egor/MovieProject2/bids_data/derivatives/group_analysis/backtothefuture/df_eyelink_calibration_errors.csv", index=False)
