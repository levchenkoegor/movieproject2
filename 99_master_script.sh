#!/bin/bash

# Run the whole pipeline from the bids conversion to the very end (lots of comp resources are needed)
# The pipeline was executed in a step-by-step manner

# conversion to bids, freesurfer, sswarper and suma
sudo nohup bash analysis/01_convert_to_bids.sh > analysis/logs/01_convert_to_bids.out &
nohup bash analysis/02_run_freesurfer.sh > analysis/logs/02_run_freesurfer.out &
nohup bash analysis/03_run_sswarper.sh > analysis/logs/03_run_sswarper.out &
nohup bash analysis/04_run_suma.sh > analysis/logs/04_run_suma.out &

# backtothefuture
nohup bash analysis/backtothefuture/01_run_preprocessing.sh > analysis/logs/01_run_preprocessing_btf.out &

# somatotopy
nohup bash analysis/somatotopy/01_preprocess_somatotopy.sh > analysis/logs/01_preprocess_somatotopy.out &

# tonotopy
nohup bash analysis/tonotopy/01_preprocess_tonotopy.sh > analysis/logs/01_preprocess_tonotopy.out &

# retinotopy
nohup bash analysis/retinotopy/01_preprocess_retinotopy.sh > analysis/logs/01_preprocess_retinotopy.out &
