import pandas as pd
import numpy as np
import ast
import re

from scipy.stats import norm
from pathlib import Path


def calculate_rates(tono_responses, times):
    hit_count = 0
    false_alarm_count = 0

    # values from the experiment (257(?) sequences in total)
    num_signals = 12
    num_noises = 244

    # Dictionary to store the last response window index for each condition
    last_hit_window = {}

    for index, row in tono_responses.iterrows():
        response_time = row['responses_rt']
        condition = row['condition']

        # Filter correct times by condition
        correct_times = times[times['cond'] == condition]

        # Check for hits within valid windows
        hit_registered = False
        for i, time_row in correct_times.iterrows():
            if time_row['start'] <= response_time <= time_row['stop']:
                if condition in last_hit_window and last_hit_window[condition] == i:
                    break  # Ignore this response, it's in the same window as a previous hit
                last_hit_window[condition] = i
                hit_count += 1
                hit_registered = True
                break

        if not hit_registered and response_time not in last_hit_window.values():
            false_alarm_count += 1

    hit_rate = hit_count / len(correct_times)
    fa_rate = false_alarm_count / num_noises

    # Applying Stanislaw and Todorov (1999) corrections
    if hit_rate == 1:
      hit_rate = (num_signals - 0.5) / num_signals
    if hit_rate == 0:
      hit_rate = 0.5 / num_signals

    if fa_rate == 1:
      fa_rate = (num_noises - 0.5) / num_noises
    if fa_rate == 0:
      fa_rate = 0.5 / num_noises

    # Calculate d-prime
    d_prime = norm.ppf(hit_rate) - norm.ppf(fa_rate)

    return hit_rate, fa_rate, d_prime


# Read CSV files with correct responses and add a 'cond' column
root_path = Path(r'/data/elevchenko/MovieProject2/')

down1 = pd.read_csv(root_path/'stimuli/task-tonotopy_condition-down_ver-1_run-1_true_responses_sorted.csv', header=None, names=['begin_repeat'])
down1['cond'] = 'down1'
up1 = pd.read_csv(root_path/'stimuli/task-tonotopy_condition-up_ver-1_run-2_true_responses_sorted.csv', header=None, names=['begin_repeat'])
up1['cond'] = 'up1'


# Combine dataframes
times = pd.concat([down1, up1], ignore_index=True)

# Compute start and stop times (which would be considered as correct response)
times['start'] = times['begin_repeat'] + 72/45
times['stop'] = times['start'] + 48/45


# Find all data files
file_names = [csv_file for csv_file in root_path.glob('raw_data/**/*tonotopic*direction*[0-9].csv')]
tono_responses_all = []
tono_summary_all = []

for n in sorted(file_names):
  # Skip bad files
  if any(substring in str(n) for substring in ['05-13_18h46.11.097',
                                               '05-21_19h22.04.642',
                                               '08-07_11h52.09.386']):
    continue

  # Read in data
  tono = pd.read_csv(n)
  tono_responses = pd.DataFrame(columns=['subject', 'condition', 'responses', 'responses_rt'])

  # Figure out condition
  conditions = {("down", 1): "down1", ("up", 1): "up1"}
  subj_bids_id = re.search(r'sub-\d+', str(n)).group(0)

  # Unpack info from csv columns
  tono_responses['responses'] = tono['collect_resp.keys'].apply(
      lambda x: ast.literal_eval(x) if pd.notna(x) else np.nan).dropna().explode().reset_index(drop=True)
  tono_responses['responses_rt'] = tono['collect_resp.rt'].apply(
      lambda x: ast.literal_eval(x) if pd.notna(x) else np.nan).dropna().explode().reset_index(drop=True)

  tono_responses['subject'] = subj_bids_id
  tono_responses['condition'] = tono_responses['condition'].fillna(
      tono.apply(lambda row: conditions[(row['up_or_down'], row['version'])], axis=1)[0])

  # Calculate rates
  hit_rate, fa_rate, d_prime = calculate_rates(tono_responses, times)

  # Append responses for future saving
  tono_responses_all.append(tono_responses)
  tono_summary_all.append(pd.DataFrame(
   {'subject': subj_bids_id,
    'condition': tono_responses['condition'][0],
    'hit_rate': hit_rate,
    'fa_rate': fa_rate,
    'd_prime': d_prime}, index=[0]))

  print(f"Subject: {subj_bids_id}, Condition: {tono_responses['condition'][0]}")
  print(f"Hit Rate: {np.round(hit_rate*100, 2)}%")
  print(f"False Alarm Rate: {np.round(fa_rate*100, 2)}%")
  print(f"D-prime: {np.round(d_prime, 2)}\n")

# save
output_path = Path(root_path/'bids_data/derivatives')

if not output_path.exists():
  output_path.mkdir(parents=True)

#df_tono_responses_all = pd.concat(tono_responses_all)
#df_tono_responses_all.to_csv(output_path/'tonotopy_responses_all.csv')

df_tono_summary_all = pd.concat(tono_summary_all).round(2)
df_tono_summary_all.to_csv(output_path/'tonotopy_accuracy_all.csv', index=False)
