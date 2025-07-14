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

%% Surface projection (and normalisation) to fsaverage
fprintf('Surface projection (and normalisation) to fsaverage\n');

for i = 1:length(subjects)
    subj = subjects{i}; % 'sub-01'

    for h = 1:length(hem)
        hemi = hem{h};

        % Input file: lh_sub-01_task_retinotopy_pRF_Gaussian
        filename = sprintf('%s_%s_task_retinotopy_pRF_Gaussian', hemi, subj);
        NatSrf = fullfile(p.FS_subDIR, subj, 'retinotopy', filename);

        % Mesh and output folders
        MeshFolder = fullfile(p.FS_subDIR, subj, 'surf');
        TmpFolder = fullfile(p.FS_subDIR, 'fsaverage');

        % Run Native2TemplateMap
        map_dir = fileparts(NatSrf);
        curr_dir = pwd;
        cd(map_dir);
        fprintf('Projecting %s to fsaverage...\n', filename);
        Native2TemplateMap(NatSrf, MeshFolder, TmpFolder);
        cd(curr_dir);

        % Update Structural field to fsaverage
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
end
