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
d = dir(fullfile(p.FS_subDIR, 'sub-*'));
all_subjects = {d([d.isdir]).name};
%all_subjects = {'sub-02', 'sub-03'}; % for testing purposes
bad_subjects = {'sub-07', 'sub-17', 'sub-29'};  % based on visual inspection

% Remove bad subjects
subjects = setdiff(all_subjects, bad_subjects);
fprintf('Including %d subjects, excluding %d bad subjects.\n', length(subjects), length(bad_subjects));

% Preallocate storage for all subject maps
for h = 1:length(hem)
    Srf_all{h} = [];  % to hold data from all subjects
end

% Load _sn.mat surface files for each subject
included_subject_count = 0;

for s = 1:length(subjects)
    subj = subjects{s};
    fprintf('\nProcessing %s...\n', subj);
    subj_folder = fullfile(p.FS_subDIR, subj, 'retinotopy');

    valid = true;
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
            valid = false;
        end
    end

    if valid
        included_subject_count = included_subject_count + 1;
    end
end

% Compute and save group-average map
for h = 1:length(hem)
    Srf = Srf_template{h};  % start from last subjects Srf
    Srf.Data = squeeze(nanmean(Srf_all{h}, 1));  % average across subjects

    outdir = fullfile(p.FS_subDIR, 'fsaverage', 'retinotopy');
    if ~exist(outdir, 'dir')
        mkdir(outdir);
    end

    outname = sprintf('%s_task_retinotopy_pRF_fsaverage_nsubj-%02d.mat', hem{h}, included_subject_count);
    outpath = fullfile(outdir, outname);
    save(outpath, 'Srf');
    fprintf('Saved average map to: %s\n', outpath);
end
