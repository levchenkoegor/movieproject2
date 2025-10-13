from pathlib import Path
import pandas as pd

# Define file paths using pathlib
root_path = Path(r'/egor2/egor/MovieProject2/')

raw_data_path = root_path / 'raw_data'
output_path = root_path / 'bids_data' / 'sourcedata'
cognitron_file = raw_data_path / "Cognitron_assessment_participants.tsv"
notes_file = raw_data_path / "Subjects_movieproject2_notes_during_scannings.csv"
output_file = output_path / "Cognitron_assessment_participants_cleaned.tsv"

# Ensure the output directory exists
output_path.mkdir(parents=True, exist_ok=True)

# Load the data
cognitron_data = pd.read_csv(cognitron_file, sep="\t")
notes_data = pd.read_csv(notes_file)

# Strip notes in parentheses from the Cognitron ID in the notes file
notes_data["Cognitron ID"] = notes_data["Cognitron ID"].str.split("(", n=1).str[0].str.strip()

# Merge the data on Cognitron ID, dropping unmatched rows
merged_data = pd.merge(
    cognitron_data,
    notes_data,
    left_on="user_code",  # Match user_code in Cognitron data
    right_on="Cognitron ID",  # Match Cognitron ID in notes data
    how="inner"  # Keep only matched rows
)

# Use the sub-id from the notes file directly
merged_data.rename(columns={"Sub-id": "sub-id"}, inplace=True)

# Reorganize columns: Keep sub-id first, followed by all columns from Cognitron data
columns_order = ["sub-id"] + [col for col in cognitron_data.columns if col != "sub-id"]
cleaned_data = merged_data[columns_order]

# Sort by sub-id
cleaned_data = cleaned_data.sort_values(by="sub-id")

# Save the cleaned data to the output file
cleaned_data.to_csv(output_file, sep="\t", index=False)

print(f"File cleaned and saved to: {output_file.resolve()}")
