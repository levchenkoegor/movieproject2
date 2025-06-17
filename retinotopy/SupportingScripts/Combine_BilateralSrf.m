function Combine_BilateralSrf(p,MapType,SrfFolder,RoiLabel,srfprefix)

% This script will plot the back-projection of the fMRI responses into the
% visual space, by using the pRF data and the contrast responses (xx_con)
clear all;
close all;
clc;

if nargin < 1
    disp('..... SELECT DIRECTORY FOLDER FOR THE MAIN PROJECT')
    p.Home  = uigetdir();
    p.FS_subDIR = [p.Home filesep 'subjects'];
    
    answer = inputdlg({'SUBJECT ID','BENSON (0) OR NATIVE (1) RETINOTOPIC MAPS','NAME pRF FOLDER OF INTEREST','ROI LABEL(S)','GENERAL LABEL FOR Srf FILE OF INTEREST'},'PARAMETERS',[1 35],...
        {'YYMMDDInIn','1','pRF_FS','V1','NonEq'});
    p.subNames = answer{1};
    MapType = str2num(answer{2});
    SrfFolder = answer{3};
    RoiLabel = split(answer{4},',');
    srfprefix = answer{5};
end
hemlabel = {'lh','rh'};

% Change directory to pRF folder
if MapType == 1
    pRFFolder = fullfile(p.FS_subDIR,p.subNames,SrfFolder);
elseif MapType == 0
    pRFFolder = fullfile(p.FS_subDIR,p.subNames,'benson');
end
cd(pRFFolder)

%% For pRF
if MapType == 1
    pRFLabel = [srfprefix '1_pRF_Gaussian'];
elseif MapType == 0
    pRFLabel = 'benson';
end

SrfL = load(char(fullfile(pRFFolder,[hemlabel{1} '_' pRFLabel '.mat'])));
SrfR = load(char(fullfile(pRFFolder,[hemlabel{2} '_' pRFLabel '.mat'])));

% Combine Srf from both hemispheres
Srf = samsrf_bilat_srf(SrfL.Srf, SrfR.Srf);
filename = char(fullfile(pRFFolder,['bi_' pRFLabel '.mat']));
save(filename,'Srf','-v7.3')

% Create the anatomical structure (Anat) for bilateral Srf
samsrf_anatomy_srf(filename)

%% Bilateral Label Creation
d = dir( char(fullfile(pRFFolder,'bi_*.mat')));
for roi = 1:length(RoiLabel)
    if MapType == 1
        filename = char(fullfile(pRFFolder,'ROIs_NonEq1_pRF_Gaussian_postfit_01',[RoiLabel{roi} '.label']));
        RoiPath =  char(fullfile(pRFFolder,'ROIs_NonEq1_pRF_Gaussian_postfit_01',RoiLabel{roi}));
    elseif MapType == 0
        filename = char(fullfile(pRFFolder,'ROIs_Benson',[RoiLabel{roi} '.label']));
        RoiPath =  char(fullfile(pRFFolder,'ROIs_Benson',RoiLabel{roi}));
    end
    
    if ~exist(filename)
        load([d.folder filesep d.name])
        % Combine labels from both hemispheres
        samsrf_bilat_label(Srf,RoiPath)
    end
end
disp('Done')
end