## Overview

This repository contains scripts for converting data to a BIDS-compliant format, preprocessing, analysing, and plotting data from the *Naturalistic Neuroimaging Database 3T+ (NNDb3T+)*. The accompanying paper, which describes the tasks, MRI protocols, quality control procedures, and more, is available [here](https://www.biorxiv.org/content/10.1101/2025.09.25.678556v2). The dataset itself is available on the [OpenNeuro repository](https://openneuro.org/datasets/ds006642/versions/1.0.1). All scripts used to analyse specific tasks (backtothefuture, somatotopy, retinotopy, tonotopy) are provided in the relevant folders.

## Repository Structure

Here is a summary of the main files and folders:

| Script / Folder | Purpose |
|-----------------|---------|
| `conda-py-env.yml` | Conda environment specification file. |
| `01_convert_to_bids.sh` `add_intendedfor_field.py` `cognitron_tobidsfolder.py` `heuristic_sess01.py` `heuristic_sess02.py` `pulselog2sourcedata.py` `retinotopy_behaviour.py` `tonotopy_behaviour.py` | Convert all raw data into BIDS format. |
| `02_run_freesurfer.sh` | Run FreeSurfer processing on raw anatomical data. |
| `03_run_sswarper.sh` | Run `SSwarper` on raw anatomical data. |
| `04_run_suma.sh` | Run SUMA to convert FreeSurfer outputs into an AFNI-friendly format. |
| `05_plot_fd_alltasks.py` | Plot framewise displacement across all tasks (Figure 2 in the paper). |
| `backtothefuture` `retinotopy` `somatotopy` `tonotopy` | Scripts used to analyse each respective task. |

## Requirements

To reproduce the outputs or run the scripts, the following dependencies are required:

- Python 3.12.8  
- Conda (or another environment manager) to create the `conda-py-env.yml` environment  
- FreeSurfer  
- AFNI  
- Bash environment for running the `.sh` scripts  
- Standard Python packages (NumPy, SciPy, pandas, matplotlib, etc.) — see `conda-py-env.yml` for exact versions  

## Contributing

If you would like to contribute:

- Open an issue for bugs, questions, or feature requests  
- Fork the repository and submit a pull request  

## How to acknowledge

If you use this code or dataset in your work, please cite the associated paper:

> [Full citation of NNDb3T+ paper once published]

Additionally, citing the dataset on [OpenNeuro](https://openneuro.org/datasets/ds006642/versions/1.0.1) is encouraged when reusing the data.  

You can also support the project by starring this repository on GitHub ⭐ — it helps others discover the resource and shows appreciation for the work.
