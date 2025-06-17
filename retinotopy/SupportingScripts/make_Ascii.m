function [p] = make_Ascii(p, subnr, setupmode)
%  [p,s] = make_Ascii(p,s)
%  converts freesurfer surface info files into ascii using Freesurfer's mris_convert
%  
%  p = structure with path/file information as defined in "run_PRF.m"
%  subnr = index of current subject analysed
%
% Created    : "2015-03-16 14:42:38 TDekker"

%setenv('FREESURFER_HOME','/Users/tessa/csurf')
FS_surfDir = fullfile(p.FS_subDIR, p.subNames{subnr}, 'surf');

if setupmode == 1
    system(['/home/inverse/freesurfer/freesurfer/bin/mris_convert -c ' fullfile(FS_surfDir, 'lh.curv') ' ' fullfile(FS_surfDir,'lh.white') ' ' fullfile(FS_surfDir,'lh.curv.asc')]);
    system(['/home/inverse/freesurfer/freesurfer/bin/mris_convert -c ' fullfile(FS_surfDir, 'rh.curv') ' ' fullfile(FS_surfDir,'rh.white') ' ' fullfile(FS_surfDir,'rh.curv.asc')]);
    system(['/home/inverse/freesurfer/freesurfer/bin/mris_convert -c ' fullfile(FS_surfDir, 'lh.area') ' ' fullfile(FS_surfDir,'lh.white') ' ' fullfile(FS_surfDir,'lh.area.asc')]);
    system(['/home/inverse/freesurfer/freesurfer/bin/mris_convert -c ' fullfile(FS_surfDir, 'rh.area') ' ' fullfile(FS_surfDir,'rh.white') ' ' fullfile(FS_surfDir,'rh.area.asc')]);
    system(['/home/inverse/freesurfer/freesurfer/bin/mris_convert -c ' fullfile(FS_surfDir, 'lh.thickness') ' ' fullfile(FS_surfDir,'lh.white') ' ' fullfile(FS_surfDir,'lh.thickness.asc')]);
    system(['/home/inverse/freesurfer/freesurfer/bin/mris_convert -c ' fullfile(FS_surfDir, 'rh.thickness') ' ' fullfile(FS_surfDir,'rh.white') ' ' fullfile(FS_surfDir,'rh.thickness.asc')]);
else
    system(['/Applications/Freesurfer/7.1.1/bin/mris_convert -c ' fullfile(FS_surfDir, 'lh.curv') ' ' fullfile(FS_surfDir,'lh.white') ' ' fullfile(FS_surfDir,'lh.curv.asc')]);
    system(['/Applications/Freesurfer/7.1.1/bin/mris_convert -c ' fullfile(FS_surfDir, 'rh.curv') ' ' fullfile(FS_surfDir,'rh.white') ' ' fullfile(FS_surfDir,'rh.curv.asc')]);
    system(['/Applications/Freesurfer/7.1.1/bin/mris_convert -c ' fullfile(FS_surfDir, 'lh.area') ' ' fullfile(FS_surfDir,'lh.white') ' ' fullfile(FS_surfDir,'lh.area.asc')]);
    system(['/Applications/Freesurfer/7.1.1/bin/mris_convert -c ' fullfile(FS_surfDir, 'rh.area') ' ' fullfile(FS_surfDir,'rh.white') ' ' fullfile(FS_surfDir,'rh.area.asc')]);
    system(['/Applications/Freesurfer/7.1.1/bin/mris_convert -c ' fullfile(FS_surfDir, 'lh.thickness') ' ' fullfile(FS_surfDir,'lh.white') ' ' fullfile(FS_surfDir,'lh.thickness.asc')]);
    system(['/Applications/Freesurfer/7.1.1/bin/mris_convert -c ' fullfile(FS_surfDir, 'rh.thickness') ' ' fullfile(FS_surfDir,'rh.white') ' ' fullfile(FS_surfDir,'rh.thickness.asc')]);
end

end