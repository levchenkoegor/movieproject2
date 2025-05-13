import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from pathlib import Path

# === Setup ===
base_dir = Path('/data/elevchenko/MovieProject2')
plots_dir = base_dir / "bids_data/derivatives/group_analysis"
plots_dir.mkdir(parents=True, exist_ok=True)

tasks = ['backtothefuture', 'somatotopy', 'retinotopy', 'tonotopy']
fd_file_pattern = 'motion_{subject_id}_enorm.1D'

def strip_sub_prefix(subject_id):
    return subject_id.replace("sub-", "")

def load_fd(subject_id, task_dir):
    subject_dir = base_dir / "bids_data/derivatives" / subject_id / task_dir
    results_pattern = f"{subject_id}.results.*"
    results_dirs = sorted(subject_dir.glob(results_pattern), reverse=True)
    if not results_dirs:
        return None
    fd_path = results_dirs[0] / fd_file_pattern.format(subject_id=strip_sub_prefix(subject_id))
    return np.loadtxt(fd_path) if fd_path.exists() else None

# === Panel Plot ===
fig, axes = plt.subplots(nrows=4, ncols=2, figsize=(18, 26))
fig.subplots_adjust(hspace=0.4, wspace=0.3)

# === Task-Specific Processing ===
for i, task in enumerate(tasks):
    task_dir = task
    subject_list = sorted([
        sub.name for sub in (base_dir / "bids_data/derivatives").iterdir()
        if (sub / task_dir).exists()
    ])

    fd_all = []
    fd_split = {}

    if task == 'backtothefuture':
        default_TRs = {"Run 1": 1352, "Run 2": 1506, "Run 3": 1592}
        special_cases = {
            "sub-01": {"Run 2": -20},
            "sub-02": {"Run 2": -8, "Run 3": 8},
            "sub-03": {"Run 1": -37},
            "sub-10": {"Run 3": -511}
        }
        excluded_subjects = {"sub-24", "sub-36"}
        subject_list = [s for s in subject_list if s not in excluded_subjects]
        fd_split = {"Run 1": [], "Run 2": [], "Run 3": []}
        for subject_id in subject_list:
            fd = load_fd(subject_id, task_dir)
            if fd is None:
                continue
            TRs = default_TRs.copy()
            if subject_id in special_cases:
                for run, adj in special_cases[subject_id].items():
                    TRs[run] += adj
            total_TRs = sum(TRs.values())
            if len(fd) < total_TRs:
                if len(fd) < TRs["Run 1"]:
                    TRs = {"Run 1": len(fd), "Run 2": 0, "Run 3": 0}
                elif len(fd) < TRs["Run 1"] + TRs["Run 2"]:
                    TRs["Run 2"] = len(fd) - TRs["Run 1"]
                    TRs["Run 3"] = 0
                else:
                    TRs["Run 3"] = len(fd) - TRs["Run 1"] - TRs["Run 2"]
            start = 0
            for run in ["Run 1", "Run 2", "Run 3"]:
                fd_run = fd[start:start + TRs[run]]
                fd_split[run].extend(fd_run)
                start += TRs[run]
        fd_all = np.concatenate(list(fd_split.values()))

    elif task == 'retinotopy':
        fd_split = {"Run 1": [], "Run 2": [], "Run 3": []}
        TRs = 348
        for subject_id in subject_list:
            fd = load_fd(subject_id, task_dir)
            if fd is not None and len(fd) >= 3 * TRs:
                fd_split["Run 1"].extend(fd[:TRs])
                fd_split["Run 2"].extend(fd[TRs:2 * TRs])
                fd_split["Run 3"].extend(fd[2 * TRs:3 * TRs])
        fd_all = np.concatenate(list(fd_split.values()))

    elif task == 'tonotopy':
        fd_split = {"Run 1": [], "Run 2": []}
        TRs = 256
        for subject_id in subject_list:
            fd = load_fd(subject_id, task_dir)
            if fd is not None and len(fd) >= 2 * TRs:
                fd_split["Run 1"].extend(fd[:TRs])
                fd_split["Run 2"].extend(fd[TRs:2 * TRs])
        fd_all = np.concatenate(list(fd_split.values()))

    elif task == 'somatotopy':
        run_sequence = pd.read_csv(base_dir / 'analysis/somatotopy/somatotopy_runssequence.csv')
        run_sequence = run_sequence.dropna(subset=['runs sequence'])
        stim_dir = base_dir / 'stimuli'
        conditions = {
            c: stim_dir / f"task-somatotopy_condition-{c.lower().replace(' ', '')}_run-both.1D"
            for c in [
                "Left face", "Left foot", "Left hand", "Left tongue",
                "Rest", "Right face", "Right foot", "Right hand", "Right tongue"
            ]
        }
        task_timing = {}
        for cond, path in conditions.items():
            with path.open() as f:
                raw = f.readlines()
            parsed = []
            for line in raw:
                for trial in line.strip().split():
                    onset, dur = map(int, trial.split(":"))
                    parsed.append((onset, dur))
            for subj in subject_list:
                if subj not in run_sequence['subj id'].values:
                    continue
                seq = run_sequence.loc[run_sequence['subj id'] == subj, 'runs sequence'].values[0].split(", ")
                half = len(parsed) // 2
                run1 = parsed[:half] if seq == ['Run 1', 'Run 2'] else parsed[half:]
                run2 = parsed[half:] if seq == ['Run 1', 'Run 2'] else parsed[:half]
                offset = sum(onset + dur for onset, dur in run1)
                adjusted = run1 + [(onset + offset, dur) for onset, dur in run2]
                task_timing.setdefault(cond, {})[subj] = adjusted
        fd_split = {}
        for cond, timing in task_timing.items():
            vals = []
            for subj, trials in timing.items():
                fd = load_fd(subj, task_dir)
                if fd is None:
                    continue
                for onset, dur in trials:
                    vals.extend(fd[onset:onset + dur])
            fd_split[cond] = vals
        fd_all = np.concatenate(list(fd_split.values()))

    # === Plot Left: Overall Histogram ===
    ax_hist = axes[i, 0]
    if len(fd_all) > 0:
        n, bins = np.histogram(fd_all, bins=100, range=(0, max(fd_all)), density=True)
        bin_width = bins[1] - bins[0]
        n_percent = n * bin_width * 100
        ax_hist.bar(bins[:-1], n_percent, width=bin_width, color='skyblue', edgecolor='black')
        ax_hist.axvline(np.percentile(fd_all, 95), color='red', linestyle='--', linewidth=1,
                        label=f'95th Percentile: {np.percentile(fd_all, 95):.2f} mm')
        ax_hist.set_xlim(-0.05, 0.8)
        ax_hist.set_ylabel("Percentage (%)")
        ax_hist.set_xlabel("Framewise Displacement (mm)")
        ax_hist.set_title("Framewise Displacement distribution across all participants")
        ax_hist.grid(axis='y', linestyle='--', alpha=0.7)
        ax_hist.legend(loc='upper right', fontsize=10)

    # === Plot Right: FD by Run/Condition ===
    ax_violin = axes[i, 1]
    if fd_split:
        data = [vals for vals in fd_split.values()]
        labels = list(fd_split.keys())
        ax_violin.violinplot(data, showextrema=False)
        ax_violin.boxplot(data, widths=0.1, showfliers=False, patch_artist=True,
                          boxprops={'color': 'blue', 'facecolor': 'lightgrey'},
                          medianprops={'color': 'red'})
        ax_violin.set_xticks(np.arange(1, len(labels) + 1))
        ax_violin.set_xticklabels(labels, rotation=45 if len(labels) > 4 else 0)
        ax_violin.set_ylim(-0.05, 0.6)
        ax_violin.set_title(f"Framewise Displacement by {'run' if 'Run' in labels[0] else 'condition'}")
        ax_violin.set_ylabel("Framewise Displacement (mm)")
        ax_violin.grid(axis='y', linestyle='--', alpha=0.7)

# === Save Output ===
output_path = plots_dir / "framewise_displacement_summary_all_tasks.png"
plt.tight_layout()
plt.savefig(output_path)
plt.close()
print(f"Summary plot saved to {output_path}")
