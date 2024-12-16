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

    # Run 1
    func_bttf_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_run-001_bold')
    func_bttf_sbref_r1 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_run-001_sbref')
    fmap_bttf_phaserev_r1 = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_dir-PA_run-001_epi')

    # Run 2
    func_bttf_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_run-002_bold')
    func_bttf_sbref_r2 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_run-002_sbref')
    fmap_bttf_phaserev_r2 = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_dir-PA_run-002_epi')

    # Run 3
    func_bttf_r3 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_run-003_bold')
    func_bttf_sbref_r3 = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_run-003_sbref')
    fmap_bttf_phaserev_r3 = create_key('sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-func_dir-PA_run-003_epi')

    # In case of movie pausing (sub 36)
    func_bttf_r1_before_pause = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_acq-beforepause_run-001_bold')
    func_bttf_sbref_r1_before_pause = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_acq-beforepause_run-001_sbref')
    func_bttf_r1_after_pause = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_acq-afterpause_run-001_bold')
    func_bttf_sbref_r1_after_pause = create_key('sub-{subject}/{session}/func/sub-{subject}_{session}_task-backtothefuture_acq-afterpause_run-001_sbref')


    info = {t1w: [], func_bttf_r1: [], func_bttf_sbref_r1: [], fmap_bttf_phaserev_r1: [],
                     func_bttf_r2: [], func_bttf_sbref_r2: [], fmap_bttf_phaserev_r2: [],
                     func_bttf_r3: [], func_bttf_sbref_r3: [], fmap_bttf_phaserev_r3: [],
                     func_bttf_r1_before_pause: [], func_bttf_sbref_r1_before_pause: [], func_bttf_r1_after_pause: [], func_bttf_sbref_r1_after_pause: []}


    # Tricks to include correct SBRef images in scenarios when the protocol was stopped and started again.
    # It creates several SBRef files which can be distinguished only by 'time' variable.
    # However, the loop below iterates over seqinfo in ascending order which means SBRef before multi-band movie task.
    # To address this issue and store only correct SBRefs and runs, the dict 'seqinfo' sorted in descending order and
    # correct SBRef image is included by 'time' variable

    seqinfo_descending = sorted(seqinfo, key=lambda item: float(item.time) if item.time is not None else float('-inf'), reverse=True)
    time_btf_run1, time_btf_run2, time_btf_run3 = 10000000000000000, 10000000000000000, 10000000000000000
    time_btf_run1_before_pause, time_btf_run1_after_pause = 10000000000000000, 10000000000000000

    # Check if the subject has not ideal scenario (more or less nii files it is supposed to be)
    if len(seqinfo_descending) > 15:
        print(f'There are more files that it is supposed to be ({len(seqinfo)}), consider checking the output...')
    elif len(seqinfo_descending) < 15:
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

        # Handling exceptions
        if s.patient_id == 'P001578': # sub-01 (glitch with the script during run 2)
            if ('task-backtothefuture_run-2' in s.series_description) and (s.dim4 == 1430):
                info[func_bttf_r2].append(s.series_id)
                time_btf_run2 = float(s.time)

        if s.patient_id == 'P001601': # sub-02 (wrong cut of movie files)
            if ('task-backtothefuture_run-3' in s.series_description) and (s.dim4 == 1616):
                info[func_bttf_r3].append(s.series_id)
                time_btf_run3 = float(s.time)

        if s.patient_id == 'P001615': # sub-03 (squeezed the ball, was uncomfortable)
            if ('task-backtothefuture_run-1' in s.series_description) and (s.dim4 == 1323):
                info[func_bttf_r1].append(s.series_id)
                time_btf_run1 = float(s.time)

        if s.patient_id == 'P001673': # sub-10 (run 3 stopped early)
            if ('task-backtothefuture_run-3' in s.series_description) and (s.dim4 == 1097):
                info[func_bttf_r3].append(s.series_id)
                time_btf_run3 = float(s.time)

        if s.patient_id == 'P001804': # sub-36 (pause during run 1)
            if ('task-backtothefuture_run-1' in s.series_description) and (s.dim4 == 400):
                info[func_bttf_r1_before_pause].append(s.series_id)
                time_btf_run1_before_pause = float(s.time)
            if ('task-backtothefuture_run-1_SBRef' in s.series_description) and (time_btf_run1_before_pause - float(s.time)) < 60:
                info[func_bttf_sbref_r1_before_pause].append(s.series_id)

            if ('task-backtothefuture_run-1' in s.series_description) and (s.dim4 == 978):
                info[func_bttf_r1_after_pause].append(s.series_id)
                time_btf_run1_after_pause = float(s.time)
            if ('task-backtothefuture_run-1_SBRef' in s.series_description) and (time_btf_run1_after_pause - float(s.time)) < 60:
                info[func_bttf_sbref_r1_after_pause].append(s.series_id)

        if s.patient_id == 'P001857': # sub-24 (pause during run 1)
            if ('task-backtothefuture_run-1' in s.series_description) and (s.dim4 == 1025):
                info[func_bttf_r1_before_pause].append(s.series_id)
                time_btf_run1_before_pause = float(s.time)
            if ('task-backtothefuture_run-1_SBRef' in s.series_description) and (time_btf_run1_before_pause - float(s.time)) < 60:
                info[func_bttf_sbref_r1_before_pause].append(s.series_id)

            if ('task-backtothefuture_run-1' in s.series_description) and (s.dim4 == 351):
                info[func_bttf_r1_after_pause].append(s.series_id)
                time_btf_run1_after_pause = float(s.time)
            if ('task-backtothefuture_run-1_SBRef' in s.series_description) and (time_btf_run1_after_pause - float(s.time)) < 60:
                info[func_bttf_sbref_r1_after_pause].append(s.series_id)


        # anat
        if ('MPRAGE-GRAPPA2-1x1x1-208sl-100pcFOV' in s.series_description) and (s.dim3 == 208):
            info[t1w].append(s.series_id)

        # back to the future
        if ('task-backtothefuture_run-1' in s.series_description) and (s.dim4 == 1360):
            info[func_bttf_r1].append(s.series_id)
            time_btf_run1 = float(s.time)
        if ('task-backtothefuture_run-1_SBRef' in s.series_description) and (time_btf_run1 - float(s.time)) < 60:
            info[func_bttf_sbref_r1].append(s.series_id)
        if ('task-backtothefuture_run-1_PErev' == s.series_description):
            info[fmap_bttf_phaserev_r1].append(s.series_id)

        if ('task-backtothefuture_run-2' in s.series_description) and (s.dim4 == 1522):
            info[func_bttf_r2].append(s.series_id)
            time_btf_run2 = float(s.time)
        if ('task-backtothefuture_run-2_SBRef' in s.series_description) and (time_btf_run2 - float(s.time)) < 60:
            info[func_bttf_sbref_r2].append(s.series_id)
        if ('task-backtothefuture_run-2_PErev' ==  s.series_description):
            info[fmap_bttf_phaserev_r2].append(s.series_id)

        if ('task-backtothefuture_run-3' in s.series_description) and (s.dim4 == 1608):
            info[func_bttf_r3].append(s.series_id)
            time_btf_run3 = float(s.time)
        if ('task-backtothefuture_run-3_SBRef' in s.series_description) and (time_btf_run3 - float(s.time)) < 60:
            info[func_bttf_sbref_r3].append(s.series_id)
        if ('task-backtothefuture_run-3_PErev' == s.series_description):
            info[fmap_bttf_phaserev_r3].append(s.series_id)


    return info
