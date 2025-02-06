from __future__ import annotations

import logging
from typing import Optional

from heudiconv.utils import SeqInfo

lgr = logging.getLogger("heudiconv")


def create_key(
    template: Optional[str],
    outtype: tuple[str, ...] = ("nii.gz",),
    annotation_classes: None = None,
) -> tuple[str, tuple[str, ...], None]:
    if template is None or not template:
        raise ValueError("Template must be a valid format string")
    return (template, outtype, annotation_classes)


def infotodict(
    seqinfo: list[SeqInfo],
) -> dict[tuple[str, tuple[str, ...], None], list[str]]:
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    t1w = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_T1w')
    t1w_5min = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-highres_T1w') # specifically for P001706

    # Somatotopy
    func_motor_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-somatotopy_run-001_bold')
    func_motor_sbref_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-somatotopy_run-001_sbref')
    func_motor_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-somatotopy_run-002_bold')
    func_motor_sbref_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-somatotopy_run-002_sbref')
    fmap_motor_phaserev = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-somatotopy_dir-PA_epi')

    # Retinotopy
    func_pRF_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-retinotopy_run-001_bold')
    func_pRF_sbref_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-retinotopy_run-001_sbref')
    func_pRF_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-retinotopy_run-002_bold')
    func_pRF_sbref_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-retinotopy_run-002_sbref')
    func_pRF_r3 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-retinotopy_run-003_bold')
    func_pRF_sbref_r3 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-retinotopy_run-003_sbref')
    fmap_pRF_phaserev = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-retinotopy_dir-PA_epi')

    # Tonotopy
    func_tonotopy_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-tonotopy_run-001_bold')
    func_tonotopy_sbref_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-tonotopy_run-001_sbref')
    func_tonotopy_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-tonotopy_run-002_bold')
    func_tonotopy_sbref_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-tonotopy_run-002_sbref')
    fmap_tonotopy_phaserev = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-tonotopy_dir-PA_epi')

    # MPM
#    t1w_mpm = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-recon{item:01d}_T1w')
#    pdw_mpm = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-recon{item:01d}_PDw')
#    mtw_mpm = create_key('sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-recon{item:01d}_MTsat')

    info = {t1w: [], t1w_5min: [], func_motor_r1: [], func_motor_sbref_r1: [], func_motor_r2: [], func_motor_sbref_r2: [], fmap_motor_phaserev: [],
           func_pRF_r1: [], func_pRF_sbref_r1: [], func_pRF_r2: [], func_pRF_sbref_r2: [], func_pRF_r3: [], func_pRF_sbref_r3: [],  fmap_pRF_phaserev: [],
           func_tonotopy_r1: [], func_tonotopy_sbref_r1: [], func_tonotopy_r2: [], func_tonotopy_sbref_r2: [], fmap_tonotopy_phaserev: []}


    # Tricks to include correct SBRef images in scenarios when the protocol was stopped and started again.
    # If the protocol stopped was stopped, it created several SBRef filesin the end which can be distinguished only by 'time' variable.
    # However, the loop below iterates over seqinfo in ascending order which means SBRef before multi-band movie task.
    # To address this issue and store only correct SBRefs and runs, the dict 'seqinfo' sorted in descending order and
    # correct SBRef image is included by 'time' variable

    seqinfo_descending = sorted(seqinfo, key=lambda item: float(item.time) if item.time is not None else float('-inf'), reverse=True)
    time_motor_run1, time_motor_run2  = 10000000000000000, 10000000000000000
    time_prf_run1, time_prf_run2, time_prf_run3, time_prf_run4 = 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000
    time_tono_run1, time_tono_run2, time_tono_run3, time_tono_run4 = 10000000000000000, 10000000000000000, 10000000000000000, 10000000000000000

    just_once = 0 # specifically for P001845

    # Check if the subject has not ideal scenario (more or less nii files it is supposed to be)
    if len(seqinfo_descending) > 38:
        print(f'There are more files that it is supposed to be ({len(seqinfo)}), consider checking the output...')
    elif len(seqinfo_descending) < 38:
        print(f'There are less files that it is supposed to be ({len(seqinfo)}), consider checking the output...')


    for s in seqinfo_descending:
        """
        The namedtuple `s` contains the following fields:

        * total_files_till_now
        * example_dcm_file
        * series_id
        * dcm_dir_name
        * unspecified2
        * unspecified3
        * dim1
        * dim2
        * dim3
        * dim4
        * TR
        * TE
        * protocol_name
        * is_motion_corrected
        * is_derived
        * patient_id
        * study_description
        * referring_physician_name
        * series_description
        * image_type
        """

        # anat
        if ('MPRAGE-GRAPPA4-1x1x1-176sl-100pcFOV' in s.protocol_name) and (s.dim3 == 176):
            info[t1w].append(s.series_id)
        if (s.patient_id == 'P001706') and ('MPRAGE-GRAPPA2-1x1x1-208sl-100pcFOV' in s.series_description):
            info[t1w_5min].append(s.series_id)


        # Somatotopy
        if ('func-bold_task-motor_run-01' in s.series_description) and (s.dim4 == 467):
            info[func_motor_r1].append(s.series_id)
            time_motor_run1 = float(s.time)
        if ('func-bold_task-motor_run-01_SBRef' in s.series_description) and (time_motor_run1 - float(s.time)) < 60:
            info[func_motor_sbref_r1].append(s.series_id)

        if ('func-bold_task-motor_run-02' in s.protocol_name) and (s.dim4 == 469):
            info[func_motor_r2].append(s.series_id)
            time_motor_run2 = float(s.time)
        if ('func-bold_task-motor_run-02_SBRef' in s.series_description) and (time_motor_run2 - float(s.time)) < 60:
            info[func_motor_sbref_r2].append(s.series_id)

        if ('func-bold_task-motor_PE-Rev' == s.series_description):
            info[fmap_motor_phaserev].append(s.series_id)


        # Retinotopy
        if ('func-bold_task-pRF_run-01' in s.series_description) and (s.dim4 == 356) and (just_once == 0):
            info[func_pRF_r1].append(s.series_id)
            time_prf_run1 = float(s.time)
            just_once = 1 # specifically for P001845
        if ('func-bold_task-pRF_run-01_SBRef' in s.series_description) and (time_prf_run1 - float(s.time)) < 60:
            info[func_pRF_sbref_r1].append(s.series_id)

        if ('func-bold_task-pRF_run-02' in s.protocol_name) and (s.dim4 == 356):
            info[func_pRF_r2].append(s.series_id)
            time_prf_run2 = float(s.time)
        if ('func-bold_task-pRF_run-02_SBRef' in s.series_description) and (time_prf_run2 - float(s.time)) < 60:
            info[func_pRF_sbref_r2].append(s.series_id)

        if ('func-bold_task-pRF_run-03' in s.protocol_name) and (s.dim4 == 356):
            info[func_pRF_r3].append(s.series_id)
            time_prf_run3 = float(s.time)
        if ('func-bold_task-pRF_run-03_SBRef' in s.series_description) and (time_prf_run3 - float(s.time)) < 60:
            info[func_pRF_sbref_r3].append(s.series_id)

        if ('func-bold_task-pRF_PE-Rev' == s.series_description):
            info[fmap_pRF_phaserev].append(s.series_id)


        # Tonotopy
        if ('func-bold_task-tono_run-01' in s.series_description) and (s.dim4 == 264):
            info[func_tonotopy_r1].append(s.series_id)
            time_tono_run1 = float(s.time)
        if ('func-bold_task-tono_run-01_SBRef' in s.series_description) and (time_tono_run1 - float(s.time)) < 60:
            info[func_tonotopy_sbref_r1].append(s.series_id)

        if ('func-bold_task-tono_run-02' in s.series_description) and (s.dim4 == 264):
            info[func_tonotopy_r2].append(s.series_id)
            time_tono_run2 = float(s.time)
        if ('func-bold_task-tono_run-02_SBRef' in s.series_description) and (time_tono_run2 - float(s.time)) < 60:
            info[func_tonotopy_sbref_r2].append(s.series_id)

        if ('func-bold_task-tono_PE-Rev' == s.series_description):
            info[fmap_tonotopy_phaserev].append(s.series_id)


        # MPM
#        if ('t1w_mfc_3dflash_v3i_R4' in s.series_description):
#            info[t1w_mpm].append(s.series_id)
#        if ('pdw_mfc_3dflash_v3i_R4' in s.series_description):
#            info[pdw_mpm].append(s.series_id)
#        if ('mtw_mfc_3dflash_v3i_R4' in s.series_description):
#            info[t1w_mpm].append(s.series_id)

    return info
