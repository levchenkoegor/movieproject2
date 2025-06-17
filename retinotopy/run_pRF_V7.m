function run_pRF_V7(SubID)
% pRF analysis script using SPM12 and SamSrf V7.13
% Adjusted for Ubuntu server setup (15/06/2025)
% Created    : "2015-03-16 14:42:38 TDekker"


%% Set defaults
nRuns = '3';
WhichFolder = 'retinotopy';
ScreenHeight = '27';
ViewingDistance = '34';

%% Set paths
p.Home = '/egor2/egor/MovieProject2';
p.FS_subDIR = fullfile(p.Home, 'bids_data', 'derivatives', 'freesurfer');
p.scriptpath = fullfile(p.Home, 'analysis', 'retinotopy');
addpath(genpath(p.scriptpath));
addpath(genpath(fullfile(p.Home, 'analysis', 'SupportingScripts')));
addpath(genpath('/egor2/egor/MovieProject2/utils/SamSrf_V7.13'));

%% Set environment variables
setenv('FSLDIR', '/tools/fsl');
setenv('FREESURFER_HOME', '/tools/freesurfer');

%% Init subject
p.subNames = char(SubID);
disp(['Subject: ' p.subNames])

nRuns = str2double(nRuns);
for i = 1:nRuns
    p.scanNames{i} = sprintf('pb02.%s.r0%d.volreg+orig', SubID, i);
    p.ppscanNames{i} = p.scanNames{i};
end

% p.batchFuntion = 'batch_job(b)';

%% Scan parameters
s = struct();
s.nVols = 348; % w/o dummy scans
s.condition = [1 1]; % Defines index for your conditions [should match the size of p.scanNames]
s.reps = [1 2]; % Index of the run number for a condition [rep number 1 and rep number 2]
s.ScreenWidth = str2double(ScreenHeight); % Height of the MRI screen in cm (BOLD = 32.4cm)
s.totdist = str2double(ViewingDistance); % Viewing distance in cm (BOLD = 107cm)
s.TR = 1; % in seconds
disp(['Scan Params: Vols=' num2str(s.nVols) ', TR=' num2str(s.TR) ', H=' num2str(s.ScreenWidth) 'cm, VD=' num2str(s.totdist) 'cm'])

%% Define pRF folder
pRFFolder = fullfile(p.FS_subDIR, p.subNames, WhichFolder);
if ~exist(pRFFolder, 'dir')
    warning(['Creating retinotopy folder: ' pRFFolder])
    mkdir(pRFFolder);
end

%% Generate occipital labels if needed
if isempty(dir(fullfile(pRFFolder, '*occ*')))
    cd(pRFFolder)
    MeshFolder = fullfile(p.FS_subDIR, p.subNames, 'surf');
    MakeOccRoi(MeshFolder, -35);  % Default Y = -35
    disp('Occipital ROI labels created.')
else
    disp('Occipital labels already exist.')
end

%% Copy aps_pRF.mat if it doesnt already exist
aps_src = '/egor2/egor/MovieProject2/presentation_scripts/Day2_tasks/2_pRFexperiment/aps_pRF.mat';
aps_dst = fullfile(pRFFolder, 'aps_pRF.mat');
if ~exist(aps_dst, 'file')
    copyfile(aps_src, aps_dst);
    disp(['Copied aps_pRF.mat to ' aps_dst])
else
    disp('aps_pRF.mat already present, skipping copy.')
end

%% Load aperture file
disp('Loading aps_pRF.mat file...')
d = dir(fullfile(pRFFolder, 'aps_pRF.mat'));
if isempty(d)
    error('aps_*.mat file not found in %s', pRFFolder)
end
apsFile = fullfile(pRFFolder, d(1).name);
load(apsFile)  % Loads ApFrm

%% Fit pRF for each hemisphere
Hemis = {'lh','rh'};
for hem = 1:length(Hemis)
    disp(['Fitting pRF for ' Hemis{hem}])
    [p, s] = fit_prf_V7(p, s, ApFrm, apsFile, Hemis{hem}, WhichFolder);
end

disp('%%%%%%% ALL DONE %%%%%%%')
end
