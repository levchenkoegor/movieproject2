function [p,s] = spm_preprocessing(p,s, subnr, sessnr)
% [p,s] = spm_preprocessing(p,s, subnr,sessnr)
% 
%  p and s are path and scan parameter storage variables respectively as defined in "run_PRF_Hugo_V7.m"
%  subnr = index of current subject analysed
%  subnr = index of current session analysed
%
% [1] Split raw 4D file into 3D volumes (fslsplit)
% [2] Moves dummy scans to folder 'dummies' - 4 dummy volumes 
% [3] If 3T: calculate VDM file
% [4] Run Realign+Unwarp (estimate) and Dual-Coregistration (estimate)
% [5] Merges 3D output files into 4D file + Cleanning-up
%
% Useful links for FieldMapping correction
%   https://lcni.uoregon.edu/kb-articles/kb-0003
%   http://www.fil.ion.ucl.ac.uk/spm/data/fieldmap/
%   https://www.youtube.com/watch?v=Y4i1FFgWz_g
%
% NOTICE: This script is run through "run_PRF_Hugo_V7.m"
% 
% Created : "2015-03-16 14:42:38 TDekker"
% Last Edit: "2022-01-15 17:07:00 Hugo Chow-Wing-Bom"
%%
disp('Initiating SPM')
spm fmri
% spm_get_defaults('cmdline',true);%suppresses gui output

%%  Identify structurals
b = struct();
b.slabsel = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, 'ALIGNMENT.nii,1'));
b.mprage = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, 'MPRAGE.nii,1'));
% Copy MPRAGE to subjects folder
SOURCE = b(1).mprage(1:end-2);
DESTINATION = char(p.pRFFolder);
copyfile(SOURCE,DESTINATION)

%% Load EPI data
for scannr = 1:s.nRuns
   %% Identify EPI volumes
    d = dir(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr}, 'vol*.nii'));
    if isempty(d)
        % The following will extend a nii file into all its volumes
        % using fslplit
        inputname = fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},[p.scanNames{scannr} '.nii']);
        outputname = fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},['vol']);
        % Extend the prf nii file into all volumes (directly in .nii format)
        disp(['Extending pRF nii file into volumes for ' p.scanNames{scannr} ' using fslsplit'])
        command = ['FSLOUTPUTTYPE=NIFTI; export FSLOUTPUTTYPE; ${FSLDIR}/bin/fslsplit ' inputname ' ' outputname];
        system(command);
    else
        disp([p.scanNames{scannr} ': pRF nii file already extended into volumes'])
    end
    
    % Place first four dummy scans in separate dir
    if ~exist(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},'dummies'))
        mkdir(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},'dummies'));
    end
    
    d = dir(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr}, [p.dumscans{1} '.nii']));
    if ~isempty(d)
        for dum = 1:length(p.dumscans)
            SOURCE = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},p.dumscans{dum}));
            DESTINATION = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},'dummies'));
            movefile(SOURCE,DESTINATION)
        end
    end
    
    % Load remaining EPI data to b structure
    StartPoint = str2num(p.dumscans{end}(end-1)); % Start from the last dummyscan
    b(scannr).data = cell(s.nVols,1);
    for i = 1:s.nVols
        nr = num2str(i+StartPoint,'%04.f');
        b(scannr).data{i,:} = char(strcat([p.sessionDIR filesep p.sessNames{sessnr,subnr} filesep p.scanNames{scannr}], '/vol', nr, '.nii,1'));
    end 
end

%% Calculate VDM File
if s.scanner == 2 && p.CalculateVDM 
    b(1).calculateVDM = 1; 
    for scannr = 1:s.nRuns
        % Retrieve information from json files
        [infoEPI,infoMag1,infoMag2,infoPh] = Read_JsonHeader(p,subnr,sessnr,scannr);
        
        % For calculating VDM file (fieldmap)
        % Echo times (short,long) used for the fieldmapping sequence
        d = dir(char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr},'*.nii')));
        b(1).phase = [d(contains({d(:).name},'ph')).folder filesep d(contains({d(:).name},'ph')).name ',1'];
        b(1).mag = [d(contains({d(:).name},'e1')).folder filesep d(contains({d(:).name},'e1')).name ',1'];
        b(1).TE = [infoMag1.EchoTime infoMag2.EchoTime]*1000; % in ms
        b(1).maskbrain = 0; % Mask brain
        b(1).matchvdm = 1; % Match VDM to EPI
        b(scannr).EPI2UW(1) = cell(1,1); b(scannr).EPI2UW = b(scannr).data{1,:};
        if contains(infoEPI.PhaseEncodingDirection,'j-')
            b(1).blipdir = 1; % Phase encoding direction (1: P>>A)
        elseif contains(infoEPI.PhaseEncodingDirection,'j')
            b(1).blipdir = -1; % Phase encoding direction (-1: A>>P)
        end
        
        % EPI Readout timing
        b(1).READOUTTIME = (1/infoEPI.BandwidthPerPixelPhaseEncode)*1000; % in ms
        b(1).epifm = 0; % Is the fieldmap using an EPI-based sequence? (0 = no, 1 = yes)
        b(1).writeunwarped = 0; 
    end
    
    % Run Calculate VDM 
    matlabbatch = CalculateVDM(b);
    spm('defaults', 'FMRI');
    spm_jobman('serial', matlabbatch);
    
    % Move created files for each run to appropriate folder
    d = dir(char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr},['*session*.nii'])));
    for scannr = 1:s.nRuns
        SOURCE = [d(scannr).folder filesep d(scannr).name];
        DESTINATION = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr}));
        movefile(SOURCE,DESTINATION);
        b(scannr).vdmfile = char(fullfile(DESTINATION,[d(scannr).name ',1']));
    end
else
   disp('Skip: Calculate VDM file') 
   b(1).calculateVDM = 0;
end

%% For each run: Realign & unwarp + Coregistration - Common for 1.5T and 3T 
% The only exception is that if 3T, previously created VDM file will be loaded
if s.scanner == 1
    for scannr = 1:s.nRuns
        % Run matlabbatch job
        disp(['Analysing: ' fullfile(p.sessNames{sessnr,subnr}, p.scanNames{scannr})])
        
        % Steps are:
        % 1) spatial.realignunwarp
        % 2) spatial.coreg.estimate to ALIGNMENT
        % 3) spatial.coreg.estimate to MPRAGE
        matlabbatch = [];
        matlabbatch = batch_job(b,s,scannr);
        
        spm('defaults', 'FMRI');
        spm_jobman('serial', matlabbatch);
    end
elseif s.scanner == 2
    matlabbatch = [];
    if p.Coregister == 1
        matlabbatch = batch_job_3T_single(b);
    elseif p.Coregister == 2
        matlabbatch = batch_job_3T_dual(b);
    end
    spm('defaults', 'FMRI');
    spm_jobman('serial', matlabbatch);
end

%% Merge to 4D and clean up
for scannr = 1:s.nRuns
    
    % Merge files back into 4D format
    for i = 1:s.nVols
        StartPoint = str2num(p.dumscans{end}(end-1)); % Start from the last dummyscan
        nr = num2str(i+StartPoint,'%04.f');
        b(scannr).preProcData{i,:} = char(strcat([p.sessionDIR filesep p.sessNames{sessnr,subnr} filesep p.scanNames{scannr}], '/uvol', nr, '.nii,1'));
    end
    SOURCE = b(scannr).preProcData;
    DESTINATION = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr}, p.ppscanNames{scannr}));
    spm_file_merge(SOURCE,DESTINATION);
    
    % Copy to 4D file to subjects folder
    SOURCE = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr},[p.ppscanNames{scannr} '.nii']));
    DESTINATION = char(p.pRFFolder);
    copyfile(SOURCE,DESTINATION)
    
    % Delete unnecessary scans and folder
    SOURCE = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}, p.scanNames{scannr}));
    delete([SOURCE filesep 'vol*.nii']);
    delete([SOURCE filesep 'uvol*.nii']);
    rmdir([SOURCE filesep 'dummies'],'s')
end

SOURCE = char(fullfile(p.sessionDIR, p.sessNames{sessnr,subnr}));
delete([SOURCE filesep '*sc*gre_field*.nii'])
delete([SOURCE filesep '*m*gre_field*.nii'])
delete([SOURCE filesep '*bmask*gre_field*.nii'])

end