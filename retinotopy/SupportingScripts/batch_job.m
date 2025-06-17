function [matlabbatch]=batch_job(b,s,scannr)

%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev: 4252 $)
%-----------------------------------------------------------------------
%%
matlabbatch{1}.spm.spatial.realignunwarp.data.scans = b(scannr).data;
if s.scanner == 1
    matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan = '';
elseif s.scanner == 2
    matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan = {b(scannr).vdmfile};
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

matlabbatch{2}.spm.spatial.coreg.estimate.ref =  {b(1).slabsel};
matlabbatch{2}.spm.spatial.coreg.estimate.source(1) = cfg_dep;
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).tname = 'Source Image';
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).tgt_spec{1}(1).value = 'image';
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).tgt_spec{1}(2).value = 'e';
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).sname = 'Realign & Unwarp: Unwarped Mean Image';
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{2}.spm.spatial.coreg.estimate.source(1).src_output = substruct('.','meanuwr');
matlabbatch{2}.spm.spatial.coreg.estimate.other(1) = cfg_dep;
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).tname = 'Other Images';
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(1).value = 'image';
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(2).value = 'e';
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).sname = 'Realign & Unwarp: Unwarped Images (Sess 1)';
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{2}.spm.spatial.coreg.estimate.other(1).src_output = substruct('.','sess', '()',{1}, '.','uwrfiles');
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{2}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

matlabbatch{3}.spm.spatial.coreg.estimate.ref = {b(1).mprage};
matlabbatch{3}.spm.spatial.coreg.estimate.source =  {b(1).slabsel};
matlabbatch{3}.spm.spatial.coreg.estimate.other(1) = cfg_dep;
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).tname = 'Other Images';
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(1).name = 'filter';
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(1).value = 'image';
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(2).name = 'strtype';
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).tgt_spec{1}(2).value = 'e';
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).sname = 'Coregister: Estimate: Coregistered Images';
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).src_exbranch = substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{3}.spm.spatial.coreg.estimate.other(1).src_output = substruct('.','cfiles');
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

end