%% Batch MGH to SamSrf MAT conversion (auto-discover subjects)
clear all; clc;

% Set environment
setenv('FREESURFER_HOME','/tools/freesurfer');
setenv('FSLDIR','/tools/fsl');

% Setup paths
p.Home = '/egor2/egor/MovieProject2';
p.FS_subDIR = [p.Home '/bids_data/derivatives/freesurfer'];
p.retinoDIR = [p.Home '/bids_data/derivatives'];
p.SamSrf = '/egor2/egor/MovieProject2/utils/SamSrf_V7.13';
addpath(genpath(p.SamSrf))

Prefix = 'vol2surf';
Bilateral = 1;
hemlabel = {'lh', 'rh'};

% === Discover all valid subject folders ===
all_entries = dir(fullfile(p.retinoDIR, 'sub-*'));
sub_dirs = all_entries([all_entries.isdir]);
subjects = {};

for i = 1:length(sub_dirs)
    subj_path = fullfile(p.retinoDIR, sub_dirs(i).name, 'retinotopy');
    if exist(subj_path, 'dir')
        subjects{end+1} = sub_dirs(i).name;
    end
end
subjects = {'sub-01', 'sub-02'};  % TEST
disp(['Found ' num2str(length(subjects)) ' subjects with retinotopy data.'])

for s = 1:length(subjects)
    SubID = subjects{s};
    saveDir = fullfile(p.FS_subDIR, SubID, 'retinotopy');
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    subjFolder = fullfile(p.retinoDIR, SubID, 'retinotopy');

    % === Find timestamped folder
    ts_dirs = dir(fullfile(subjFolder, [SubID '.results*']));
    if isempty(ts_dirs)
        warning(['No timestamp folder found for ' SubID ', skipping.']);
        continue
    end

    % Use the most recent one
    [~, idx_latest] = max([ts_dirs.datenum]);
    TimestampFolder = ts_dirs(idx_latest).name;
    fMRIFolder = fullfile(subjFolder, TimestampFolder);
    surffile = fullfile(p.FS_subDIR, SubID, 'surf');
    anatpath = fullfile(p.FS_subDIR, SubID, 'mri');

    % === Locate MGH files
    files = dir(fullfile(fMRIFolder, ['*' Prefix '*.mgh']));
    scanlist = fullfile({files.folder}, {files.name});

    if isempty(scanlist)
        warning(['No MGH files found for ' SubID ', skipping.']);
        continue
    end

    % === Per hemisphere
    for hem = 1:length(hemlabel)
        funimg = {};
        idx = 0;
        for i = 1:length(scanlist)
            [~, name, ~] = fileparts(scanlist{i});
            if startsWith(name, hemlabel{hem})
                idx = idx + 1;
                funimg{idx} = scanlist{i};
            end
        end

        if isempty(funimg)
            warning(['No ' hemlabel{hem} ' files for ' SubID ', skipping hemisphere.']);
            continue;
        end

        nrmls = true; avrgd = true; nsceil = true;
        hemsurf = fullfile(surffile, hemlabel{hem});

        disp(['Converting for ' SubID ' | ' hemlabel{hem}])

        origDir = pwd;
        cd(fMRIFolder)
        samsrf_mgh2srf(funimg, hemsurf, nrmls, avrgd, nsceil, anatpath)

        % Move output directly to freesrufer subjFolder (retinotopy/)
        [~, first_name, ~] = fileparts(funimg{1});
        defaultOutFile = [first_name '.mat'];
        newOutFile = fullfile(saveDir, [hemlabel{hem} '_' Prefix '_' SubID '_avg.mat']);
        if exist(defaultOutFile, 'file')
            movefile(defaultOutFile, newOutFile);
        else
            warning(['Expected output not found: ' defaultOutFile])
        end
        cd(origDir)
    end

    % === Bilateral .mat
    Lfile = fullfile(saveDir, ['lh_' Prefix '_' SubID '_avg.mat']);
    Rfile = fullfile(saveDir, ['rh_' Prefix '_' SubID '_avg.mat']);
    if exist(Lfile, 'file') && exist(Rfile, 'file')
        SrfL = load(Lfile); SrfR = load(Rfile);
        Srf = samsrf_bilat_srf(SrfL.Srf, SrfR.Srf);
        save(fullfile(saveDir, ['bi_' Prefix '_' SubID '_avg.mat']), 'Srf', '-v7.3');
    else
        warning(['Bilateral merge skipped for ' SubID ', one hemisphere missing.']);
    end

    disp(['..... DONE with ' SubID ' .....']);
end

disp('All subjects completed.')
