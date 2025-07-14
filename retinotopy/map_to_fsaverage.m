%% Convert the map to fsaverage
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

% Get all subject directories in p.FS_subDIR
d = dir(fullfile(p.FS_subDIR, 'sub-*'));
subjects = {d([d.isdir]).name}; % cell array of 'sub-01', 'sub-02', etc.
% subjects = {'sub-01', 'sub-02'}; % for a test

%% Surface projection (and normalisation) to fsaverage
fprintf('Surface projection (and normalisation) to fsaverage\n');

for i = 1:length(subjects)
    subj = subjects{i};

    try
        retino_dir = fullfile(p.FS_subDIR, subj, 'retinotopy');
        if ~exist(retino_dir, 'dir')
            warning('Skipping %s: no retinotopy folder found.', subj);
            continue;
        end

        for h = 1:length(hem)
            hemi = hem{h};

            % File: lh_sub-01_task_retinotopy_pRF_Gaussian.mat
            filename = sprintf('%s_%s_task_retinotopy_pRF_Gaussian', hemi, subj);
            NatSrf = fullfile(retino_dir, filename);
            if ~exist([NatSrf '.mat'], 'file')
                warning('Skipping %s: missing file %s', subj, filename);
                continue;
            end

            MeshFolder = fullfile(p.FS_subDIR, subj, 'surf');
            TmpFolder = fullfile(p.FS_subDIR, 'fsaverage');

            % Go to map dir and run projection
            map_dir = fileparts(NatSrf);
            curr_dir = pwd;

            cd(map_dir);
            fprintf('Projecting %s to fsaverage...\n', filename);
            Native2TemplateMap(filename, MeshFolder, TmpFolder);
            cd(curr_dir);

            % Update Structural field
            sn_file = [NatSrf '_sn.mat'];

            if exist(sn_file, 'file')
                fprintf('Updating Structural path in: %s\n', sn_file);
                load(sn_file, 'Srf');
                Srf.Structural = fullfile(TmpFolder, 'surf');
                save(sn_file, 'Srf');
            else
                warning('File not found: %s', sn_file);
            end
        end
    catch ME
        warning('Error processing %s: %s', subj, ME.message);
        continue;
    end
end
