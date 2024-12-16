#!/bin/bash

# Run the whole pipeline from the conversion to bids to the end (lots of comp resources are needed)

sudo nohup bash analysis/s1_convert_to_bids.sh > analysis/logs/s1_convert_to_bids.out &
nohup bash analysis/s2_freesurfer.sh > analysis/logs/s2_freesurfer.out &
nohup bash analysis/s3_qc_moviewatching_afni.sh > analysis/logs/s3_qc_moviewatching_afni.out &
nohup bash analysis/s4_qc_somatotopy_afni.sh > analysis/logs/s4_qc_somatotopy_afni.out &
