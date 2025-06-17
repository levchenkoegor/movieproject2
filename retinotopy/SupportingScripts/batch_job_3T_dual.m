function matlabbatch = batch_job_3T_dual(b)
%-----------------------------------------------------------------------
% Job saved on 15-Jan-2022 18:39:57 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

%% Realign & Unwarp (all runs: 1 session = 1run)
matlabbatch{1}.spm.spatial.realignunwarp.data(1).scans = b(1).data;
if b(1).calculateVDM == 1
    matlabbatch{1}.spm.spatial.realignunwarp.data(1).pmscan = {b(1).vdmfile};
else
    matlabbatch{1}.spm.spatial.realignunwarp.data(1).pmscan = '';
end
matlabbatch{1}.spm.spatial.realignunwarp.data(2).scans = b(2).data;
if b(1).calculateVDM == 1
    matlabbatch{1}.spm.spatial.realignunwarp.data(2).pmscan = {b(2).vdmfile};
else
    matlabbatch{1}.spm.spatial.realignunwarp.data(2).pmscan = '';
end
matlabbatch{1}.spm.spatial.realignunwarp.data(3).scans = b(3).data;
if b(1).calculateVDM == 1
    matlabbatch{1}.spm.spatial.realignunwarp.data(3).pmscan = {b(3).vdmfile};
else
    matlabbatch{1}.spm.spatial.realignunwarp.data(3).pmscan = '';
end
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 4;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 2;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';

%% Coregistration to ALIGNMENT
matlabbatch{2}.spm.spatial.coreg.estimate.ref = {b(1).slabsel};
matlabbatch{2}.spm.spatial.coreg.estimate.source(1) = cfg_dep('Realign & Unwarp: Unwarped Mean Image', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
matlabbatch{2}.spm.spatial.coreg.estimate.other(1) = cfg_dep('Realign & Unwarp: Unwarped Images (Sess 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','uwrfiles'));
matlabbatch{2}.spm.spatial.coreg.estimate.other(2) = cfg_dep('Realign & Unwarp: Unwarped Images (Sess 2)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{2}, '.','uwrfiles'));
matlabbatch{2}.spm.spatial.coreg.estimate.other(3) = cfg_dep('Realign & Unwarp: Unwarped Images (Sess 3)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{3}, '.','uwrfiles'));
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

%% Coregistration to MPRAGE
matlabbatch{3}.spm.spatial.coreg.estimate.ref = {b(1).mprage};
matlabbatch{3}.spm.spatial.coreg.estimate.source = {b(1).slabsel};
matlabbatch{3}.spm.spatial.coreg.estimate.other(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
end