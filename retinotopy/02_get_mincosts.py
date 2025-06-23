import os
import glob
import pandas as pd

# Define root path
root_path = '/egor2/egor/MovieProject2/bids_data/derivatives'

# Store results
records = []

# Search for all *.dat.mincost files in the correct path
pattern = os.path.join(root_path, 'sub-*', 'retinotopy', 'sub-*.results*', '*.dat.mincost')
for dat_file in glob.glob(pattern):
    parts = dat_file.split(os.sep)
    sub_id = parts[-4]         # sub-XX
    folder_name = parts[-2]    # sub-XX.results.*

    try:
        with open(dat_file, 'r') as f:
            line = f.read().strip()
            mincost = float(line.split()[0])  # first value only
    except Exception as e:
        print(f"Error reading {dat_file}: {e}")
        continue

    records.append({
        'sub_id': sub_id,
        'folder_name': folder_name,
        'mincost': mincost
    })

# Convert to DataFrame and sort by sub_id
df = pd.DataFrame(records)
df = df.sort_values(by='sub_id')  # Sort alphabetically by sub_id

# Save to CSV
filename = 'retinotopy_mincost_per_sub.csv'
df.to_csv(f'/egor2/egor/MovieProject2/analysis/retinotopy/{filename}', index=False)
print(f"Subjects with mincost > 0.45: {df[df['mincost'] > 0.45]}")
print(f"Saved: {filename}")
