function [infoEPI,infoMag1,infoMag2,infoPh] = Read_JsonHeader(p,subnr,sessnr,scannr)

%% Retrieve file names from sessions folder
% FieldMaps
fname = cell(0,0);
d = dir(char(fullfile(p.sessionDIR,p.sessNames{sessnr,subnr})));
listname = {d(~startsWith({d.name}, '.')).name};
[~,idx] = find(contains(listname,'gre_field'));
for i = 1:length(idx)
    fname{i} = char(fullfile(p.rawdata,p.subNames{subnr},'_InfoSequence',[listname{idx(i)}(1:end-4) '.json']));
end
fname = fname(1:3);

% EPI
d = dir(char(fullfile(p.sessionDIR,p.sessNames{sessnr,subnr},[p.pRFName '*.txt'])));
filename = [d.folder filesep d.name];
fid = fopen(filename);
idxName = [];
for r = 1:length(p.ppscanNames)
    lines{r,:} = fgetl(fid);
end
fclose('all');
fname{end+1} = char(fullfile(p.rawdata,p.subNames{subnr},'_InfoSequence',[lines{scannr}(1:end-4) '.json']));

%% Match filenames to json file in _InfoSequence
% EPI
fid = fopen(fname{contains(fname,'mbep2d')});
info = fread(fid,inf);
str = char(info');
fclose(fid);
infoEPI = jsondecode(str);

% Magnitude 1 - Short TE
fid = fopen(fname{contains(fname,'e1')});
tmp = fread(fid,inf);
str = char(tmp');
fclose(fid);
infoMag1 = jsondecode(str);

% Magnitude 2 - Long TE
fid = fopen(fname{contains(fname,'e2')});
tmp = fread(fid,inf);
str = char(tmp');
fclose(fid);
infoMag2 = jsondecode(str);

% Phase
fid = fopen(fname{contains(fname,'ph')});
info = fread(fid,inf);
str = char(info');
fclose(fid);
infoPh = jsondecode(str);

end

