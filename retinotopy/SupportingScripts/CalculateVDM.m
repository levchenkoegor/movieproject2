function [matlabbatch]=CalculateVDM(b)
%-----------------------------------------------------------------------
% Job saved on 15-Jan-2022 16:17:57 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = {b(1).phase};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = {b(1).mag};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = b(1).TE;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = b(1).maskbrain;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = b(1).blipdir;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = b(1).READOUTTIME;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = b(1).epifm;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {fullfile(spm('Dir'),'toolbox/FieldMap','T1.nii')};
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(1).epi = {b(1).EPI2UW}; % Only need the first volume
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(2).epi = {b(2).EPI2UW}; % Only need the first volume
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(3).epi = {b(3).EPI2UW}; % Only need the first volume
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = b(1).matchvdm;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = b(1).writeunwarped;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = '';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;
end