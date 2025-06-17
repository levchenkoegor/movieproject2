%% Set-up Model
visang_rad = 2 * atan(27/2/34);
Ecc = visang_rad * (180/pi); % diameter
Ecc = Ecc/2; % radius
ApWidth = [size(ApFrm,1),size(ApFrm,2)];
% Which pRF model function? (default = prf_gaussian_rf)
Model.Prf_Function = @(P,ApWidth) prf_gaussian_rf(P(1), P(2), P(3), ApWidth); % Which pRF model function?
Model.Name = ['pRFGaussian']; % File name to indicate type of pRF model
Model.Param_Names = {'x0'; 'y0'; 'Sigma'}; % Names of parameters to be fitted
Model.Scaled_Param = [1 1 1]; % Which of these parameters are scaled
Model.Only_Positive = [0 0 1]; % Which parameters must be positive?
Model.Scaling_Factor = Ecc; % Scaling factor of the stimulus space (e.g. eccentricity)
Model.TR = 1; % Repetition time (TR) of pulse sequence
Model.Hrf = []; % HRF file or vector to use (empty = canonical)
Model.Aperture_File = 'aps_pRF.mat'; % Aperture file

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

% Model.Param1 & Model.Param2 are converted to cardinals coordinates in
% prf_generate_searchspace.m, which compute X and S matrices.
% X = Prediction of neuronal timecourse in % pRF activate
% S = 5-D Search Grid (although dimensions 4-5 are not used)
% X and S are saved in 'src_pRF_NonEq1_pRF_Gaussian.mat'

%% Show extent of Rfp with combination of params (x0,y0,sigma)
% 1: x0 = 0.0313, y0 = 0, sigma = 0.0206
% 29233: x0 = 0.0313, y0 = 0, sigma = 1
% 34453: x0 = 0.0313, y0 = 0, sigma = 2

% 1326: x0 = 3.06e-17, y0 = 0.5, sigma = 0.0206
% 29514: x0 = 3.06e-17, y0 = 0.5, sigma = 1
% 34734: x0 = 3.06e-17, y0 = 0.5, sigma = 2

% 287: x0 = 6.12e-17, y0 = 1, sigma = 0.0206
% 29519: x0 = 6.12e-17, y0 = 1, sigma = 1
% 34739: x0 = 6.12e-17, y0 = 1, sigma = 2

% 290: x0 = 9.28e-17, y0 = 1.5, sigma = 0.0206
% 29522: x0 = 9.28e-17, y0 = 1.5, sigma = 1
% 34742: x0 = 9.28e-17, y0 = 1.5, sigma = 2

% idx = 0; A = [];
% B = []; B = find(round(S(3,:),2) >= 1.99); 
% for i = 1:length(B)
%     A(1,i) = B(i);
%     A(2:4,i) = S(1:3,B(i));
% end
% format longG
% A(:,find(round(A(3,:),2) == 0.5))

CombSelect = [1,29233,34453,1326,29514,34734,287,29519,34739,290,29522,34742];
idx = 0;
Rect = get(0,'ScreenSize');
figure('Color','w','Position',Rect)
for n = 1:length(CombSelect)
    Rfp = Model.Prf_Function([S(1,CombSelect(n)) S(2,CombSelect(n)) S(3,CombSelect(n)) S(4,CombSelect(n)) S(5,CombSelect(n))], size(ApFrm,1)*2); % pRF profile
    cptc = prf_predict_timecourse(Rfp, ApFrm);
    
    idx = idx+1;
    subplot(4,3,idx)
    imagesc(Rfp)
    axis square
    hold on 
    viscircles([100,100],50,'Color','k','EnhanceVisibility',0);
    plot(50:150,ones(1,length(50:150))*150,'k--',50:150,ones(1,length(50:150))*50,'k--')
    plot(ones(1,length(50:150))*150,50:150,'k--',ones(1,length(50:150))*50,50:150,'k--')
    t = ['x0: ' num2str(round(S(1,CombSelect(n)),3)) ', y0: ' num2str(round(S(2,CombSelect(n)),3)) ', \sigma: ' num2str(round(S(3,CombSelect(n)),3))];
    title(t)
end