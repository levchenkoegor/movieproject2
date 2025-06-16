%% FREESURFER SURFACE PROJECTION - MGH to SamSrf mat file
% This will implement the last step of the FreeSurfer surface projection:
% the conversion of mgh files into SamSrf compatible mat files.
clear all; 
clc;

commandwindow;
if ismac()
    [~,result] = system('uname -m');
    is_silicon_mac = strcmp(strtrim(result),'arm64');
else
    is_silicon_mac = false;
end
if is_silicon_mac
    setenv('FREESURFER_HOME','/Applications/freesurfer/7.4.1')
else
    setenv('FREESURFER_HOME','/tools/freesurfer')
end
setenv('FSLDIR','/tools/fsl');  % Set environment for FSL folder

disp('...... SELECT MAIN PROJECT FOLDER ......')
p.Home = uigetdir(); % Choose main directory
p.HomeFS = p.Home;
idxspace = isspace(p.Home); % Identifty if there is a space in the path
idxbracket = contains(p.Home,'(') | contains(p.Home,')'); % Identifty if there is a space in the path
if sum(idxspace)>0 || idxbracket == 0 % If there is a space
    p.HomeFS = insertBefore(p.Home," ","\"); % Insert a backslash before the space in the path
    p.HomeFS = insertBefore(p.HomeFS,"(","\"); % Insert a backslash before the open bracket
    p.HomeFS = insertBefore(p.HomeFS,")","\"); % Insert a backslash before the close bracket
    p.HomeFS = insertBefore(p.HomeFS,"-","\"); % Insert a backslash before the close bracket
end
clear idxspace idxbracket

p.sessionDIR = [p.Home filesep 'sessions'];
p.FS_subDIR = [p.Home filesep 'subjects'];
p.scriptpath = [p.Home filesep '_AnalysisScripts/2_PreProcessing/FS_SurfaceProjection'];
addpath(genpath(p.scriptpath));
% Add SamSrf Path (assumes SamSrf permanently defined in your path directories)
[r,~,~]=fileparts(which('samsrf_mgh2srf.m'));
p.SamSrf = r(1:end-6);
disp(['SamSrf path: ' p.SamSrf])
addpath(p.SamSrf)

%%  Enter parameters of interest
answer = inputdlg({'SUBJECT ID','FOLDER NAME (prf_NonEq or fMRI_CSF_XXXcpd)', ...
    'PREFIX NII FILES (e.g., prf_NonEq, fMRI_CSF_XXXcpd, con, spmT, or spmZ)','BILATERAL OUTPUT (0/1)?'},...
    'PARAMETERS',[1 85],...
    {'YYMMDDInIn','fMRI_CSF_XXXcpd','fMRI_CSF_XXXcpd','0'});
SubID = answer{1};
FolderName = answer{2}; 
Prefix = answer{3}; 
Bilateral = str2num(answer{4});

% Session ID
answer = input('Is SUBJECT ID same as SESSION ID (Y/N)? ','s');
switch answer
    case 'Y'
        p.sessNames = SubID;
    case 'N'
        p.sessNames = input('Enter SESSION ID (format: YYMMDDInIn): ','s');
end

fMRIFolder= char(fullfile(p.FS_subDIR,SubID,FolderName));
if contains(Prefix,'fsaverage')
    surffile = char(fullfile(p.FS_subDIR,'fsaverage','surf'));
else
    surffile = char(fullfile(p.FS_subDIR,SubID,'surf'));
end

cd(fMRIFolder)
hemlabel={'lh', 'rh'};

%% Convert created mgh files into SamSrf compatible files (.mat)

if ~contains(FolderName,'CSF') % pRF
    scanlist = cellstr(spm_select('FPList',fMRIFolder,['^*_pp_' Prefix '*.*mgh']))';
    
    for hem = 1:length(hemlabel) 
        idx = 0;
        funimg = {};
        for i = 1:length(scanlist)
            % Get hemisphere label to select scans in scanlist
            tmp = []; tmp = split(scanlist{i},'/');
            tmp = split(tmp{end},'_');
            idxHemis = tmp{1};
            
            if idxHemis == hemlabel{hem}
                idx = idx+1; 
                funimg{1,idx} = scanlist{i};
            end
        end
        nrmls = true; % Detrend & z-score the time series in each vertex.
        avrgd = true; 
        nsceil = true;

        hemsurf = [surffile filesep hemlabel{hem}];
        
        if contains(funimg,'fsaverage')
            anatpath = ['..' filesep 'anatomy_fsaverage' filesep];
        else
            anatpath = ['..' filesep 'anatomy' filesep];
        end
        
        % Perform conversion
        disp(['Converting for ' hemlabel{hem}])
        samsrf_mgh2srf(funimg, hemsurf, nrmls,avrgd,nsceil,anatpath)
    end
    
    % Copy aps_pRF.mat file 
    SOURCE = [p.Home filesep '_AnalysisScripts/3b_fMRI_pRF/PreProcessing/aps_pRF.mat'];
    DESTINATION = fMRIFolder;
    copyfile(SOURCE,DESTINATION)
    
elseif contains(FolderName,'CSF')
    scanlist = cellstr(spm_select('FPList',fMRIFolder,['^*_' Prefix '*.*mgh']))';

    for i = 1:length(scanlist)
        funimg = scanlist{i};
        nrmls = true; % Detrend & z-score the time series in each vertex.
        
        % Get hemisphere for surf
        tmp = []; tmp = split(funimg,'/');
        tmp = split(tmp{end},'_');
        idxHemis = tmp{1};
        hemsurf = [surffile filesep idxHemis];
        
        % Perform conversion
        disp(['Converting ' scanlist{i}])
        samsrf_mgh2srf(funimg, hemsurf, nrmls)
    end
    
end

%% Creating bilateral Srf
if Bilateral
    d = dir(char(fullfile(fMRIFolder,['*h_*' Prefix '*.mat'])));
    SrfALL = struct;
    
    for i = 1:length(d)/2
        if contains(Prefix,'con') || contains(Prefix,'spm')
            disp([Prefix '_' num2str(i,'%04.f')])
        else
            disp([Prefix num2str(i)])
        end
        
        SrfL = []; SrfR = []; Srf = [];
        if contains(Prefix,'con') || contains(Prefix,'spm')
            SrfL = load(char(fullfile(fMRIFolder,[hemlabel{1} '_' Prefix '_' num2str(i,'%04.f') '.mat'])));
            SrfR = load(char(fullfile(fMRIFolder,[hemlabel{2} '_' Prefix '_' num2str(i,'%04.f') '.mat'])));
        elseif contains(Prefix,'fMRI_CSF') || contains(Prefix,'pRF')
            SrfL = load(char(fullfile(fMRIFolder,[hemlabel{1} '_pp_' Prefix num2str(i) '.mat'])));
            SrfR = load(char(fullfile(fMRIFolder,[hemlabel{2} '_pp_' Prefix num2str(i) '.mat'])));
        elseif ~contains(Prefix,'fMRI_CSF') && ~contains(Prefix,'pRF')
            SrfL = load(char(fullfile(fMRIFolder,d(1).name))); %lh
            SrfR = load(char(fullfile(fMRIFolder,d(2).name))); %rh
        end
        
        % Combine Srf from both hemispheres
        Srf = samsrf_bilat_srf(SrfL.Srf, SrfR.Srf); 
        
        if contains(Prefix,'con') || contains(Prefix,'spm')
            filename = char(fullfile(fMRIFolder,['bi_' Prefix '_' num2str(i,'%04.f') '.mat']));
        elseif contains(Prefix,'fMRI_CSF') || contains(Prefix,'pRF')
            if contains(funimg,'fsaverage')
                filename = char(fullfile(fMRIFolder,['bi_' Prefix num2str(i) '_fsaverage.mat']));
            else
                filename = char(fullfile(fMRIFolder,['bi_' Prefix num2str(i) '.mat']));
            end
        elseif ~contains(Prefix,'fMRI_CSF') && ~contains(Prefix,'pRF')
            filename = char(fullfile(fMRIFolder,['bi_' Prefix  num2str(i) '.mat']));
        end
        save(filename,'Srf','-v7.3')
        
    end
   
end

%% Move MGH and regdata files into a folder
DESTINATION = char(fullfile(fMRIFolder,'MGHFiles'));
if ~exist(DESTINATION,'dir')
    mkdir(DESTINATION) 
end

% Copy pp* files and txt file to fMRI_SPM folder in subjects
disp(['... Copying MGH and regdata files to MGHFiles folder'])
SOURCE = char(fullfile(fMRIFolder,['*' Prefix '*.mgh']));
movefile(SOURCE,DESTINATION)

SOURCE = char(fullfile(fMRIFolder,'*.dat*'));
d = dir(SOURCE);
if ~isempty(d)
    movefile(SOURCE,DESTINATION)
end

SOURCE = char(fullfile(fMRIFolder,'*.lta'));
d = dir(SOURCE);
if ~isempty(d)
    movefile(SOURCE,DESTINATION)
end

SOURCE = char(fullfile(fMRIFolder,'*.log'));
d = dir(SOURCE);
if ~isempty(d)
    movefile(SOURCE,DESTINATION)
end

disp('..... Conversion DONE .....')
