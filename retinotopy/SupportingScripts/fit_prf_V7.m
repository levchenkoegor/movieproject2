function [p, s] = fit_prf_V7(p,s,ApFrm,apsFile,Hemis,WhichFolder)
%  [p, s] = fit_prf(p,s,subnr)

Ecc = Visual_Angle(s.ScreenWidth, s.totdist); % diameter
Ecc = Ecc/2; % radius

prfFolder= char(fullfile(p.FS_subDIR, p.subNames, WhichFolder));
FS_surfDir = char(fullfile(p.FS_subDIR, p.subNames, 'surf'));

disp(prfFolder)
cd(prfFolder)

%% Standard 2D Gaussian pRF
% Define size of the apertures: vertical and horizontal length in pixels
ApWidth = [size(ApFrm,1),size(ApFrm,2)];
% Which pRF model function? (default = prf_gaussian_rf)
Model.Prf_Function = @(P,ApWidth) prf_gaussian_rf(P(1), P(2), P(3), ApWidth); % Which pRF model function?
Model.Name = [p.scanNames{1} '_pRF_Gaussian']; % File name to indicate type of pRF model
Model.Param_Names = {'x0'; 'y0'; 'Sigma'}; % Names of parameters to be fitted
Model.Scaled_Param = [1 1 1]; % Which of these parameters are scaled
Model.Only_Positive = [0 0 1]; % Which parameters must be positive?
Model.Scaling_Factor = Ecc; % Scaling factor of the stimulus space (e.g. eccentricity)
Model.TR = s.TR; % Repetition time (TR) of pulse sequence
Model.Hrf = []; % HRF file or vector to use (empty = canonical)
Model.Aperture_File = apsFile; % Aperture file

% Optional parameters
Model.Noise_Ceiling_Threshold = 0; % Limit data to above certain noise ceiling?
Model.Replace_Bad_Fits = false; % If true, uses coarse fit for bad slow fits
Model.Smoothed_Coarse_Fit = 0; % If > 0, smoothes data for coarse fit
Model.Coarse_Fit_Only = false; % If true, only runs the coarse fit
Model.Seed_Fine_Fit = ''; % Define a Srf file to use as seed map
Model.Fine_Fit_Threshold = 0.0000001; % Define threshold for what to include in fine fit
Model.Coarse_Fit_Block_Size = 10000; % Defines block size for coarse fit (reduce if using large search space)
Model.Polar_Search_Space = true; % If true, parameter 1 & 2 are polar (in degrees) & eccentricity coordinates

% Search grid for coarse fit
Model.Param1 = 0 : 10 : 350; % Polar search grid
Model.Param2 = 2 .^ (-5 : 0.2 : 0.6); % Eccentricity  search grid
Model.Param3 = 2 .^ (-5.6 : 0.2 : 1); % Sigma search grid
Model.Param4 = 0; % Unused
Model.Param5 = 0; % Unused

SrfFiles = [Hemis '_' p.ppscanNames{1}];
Roi = char(fullfile(prfFolder, [Hemis '_occ']));

%% Fit pRF model
disp(['Starting fitting with R2 fine-fit of ' num2str(Model.Fine_Fit_Threshold)])
MapFile = samsrf_fit_prf(Model, SrfFiles, Roi);

end
