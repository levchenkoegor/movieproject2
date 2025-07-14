%% Generate the average map across all participants (in fsaverage space)
clear all; clc;

% Set environment
setenv('FREESURFER_HOME','/tools/freesurfer');

% Setup paths
p.Home = '/egor2/egor/MovieProject2';
p.FS_subDIR = fullfile(p.Home, 'bids_data', 'derivatives', 'freesurfer');
p.SamSrf = '/egor2/egor/MovieProject2/utils/SamSrf_V7.13';
addpath(genpath(p.SamSrf))

% Hemispheres
hem = {'lh', 'rh'};

% Subjects to include in average
subjects = {d([d.isdir]).name}; % cell array of 'sub-01', 'sub-02', etc.
%subjects = {'sub-01', 'sub-02'}; % for testing purposes

% Preallocate storage for all subject maps
for h = 1:length(hem)
    Srf_all{h} = [];  % to hold data from all subjects
end

% Load _sn.mat surface files for each subject
for s = 1:length(subjects)
    subj = subjects{s};
    fprintf('\nProcessing %s...\n', subj);
    subj_folder = fullfile(p.FS_subDIR, subj, 'retinotopy');

    for h = 1:length(hem)
        hemi = hem{h};
        filename = sprintf('%s_%s_task_retinotopy_pRF_Gaussian_sn.mat', hemi, subj);
        filepath = fullfile(subj_folder, filename);

        if exist(filepath, 'file')
            load(filepath, 'Srf');
            Srf_all{h}(s,:,:) = Srf.Data;  % store subject’s data
            if s == length(subjects)
                Srf_template{h} = Srf; % use last subjects Srf struct as template
            end
        else
            warning('Missing file: %s', filepath);
        end
    end
end

% Compute and save group-average map
for h = 1:length(hem)
    Srf = Srf_template{h};  % start from last subjects Srf
    Srf.Data = squeeze(nanmean(Srf_all{h}, 1));  % average across subjects

    outname = sprintf('%s_task_retinotopy_pRF_fsaverage_nsubj-%02d.mat', hem{h}, length(subjects));
    outpath = fullfile(p.FS_subDIR, 'fsaverage', outname);
    save(outpath, 'Srf');
    fprintf('Saved average map to: %s\n', outpath);
end
