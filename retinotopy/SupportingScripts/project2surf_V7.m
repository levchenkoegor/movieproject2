
function [p,s] = project2surf_V7(p,s, subnr)
% [p,s] = project2surf(p,s, subnr)
%
%
%
%setenv('FREESURFER_HOME','/home/inverse/freesurfer/freesurfer')

Hemis={'lh', 'rh'};
FS_surfDir = fullfile(p.FS_subDIR, p.subNames{subnr}, 'surf');

% make cellarray with scannames
scanlist = cell(1,2);
for ii = 1:length(p.ppscanNames)
    scanlist{1,ii} = fullfile(p.pRFFolder,p.ppscanNames{ii});
end

cd(fullfile(p.pRFFolder))
for cc = 1:max(s.condition)
    for hh = 1:length(Hemis)
        disp(hh)
        samsrf_vol2srf(scanlist, fullfile(p.pRFFolder,'MPRAGE.nii'), ...
            fullfile(FS_surfDir, Hemis{hh}), 0.5, 'Mean', true ,true);
    end
end

end



