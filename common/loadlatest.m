function out = loadlatest(name, resdir)
% LOADLATEST Load latest data
%
%   LOADLATEST(NAME) Loads the latest 'NAME_yyyymmdd_HHMM.mat'

if nargin < 2
    resdir = '.\results';
end

if isempty(strfind(name,'.mat'))
    name = [name, '*.mat'];
end
% Most recent
files = dir(fullfile(resdir, name));
if isempty(files)
    error('loadresults:nofile','No files matching ''%s'' found.',name)
end

% Prefer exact match or take most recent
idx = ismember({files.name},name);
if ~any(idx)
    [~,idx] = max([files.datenum]);
end
s = load(fullfile(resdir,files(idx).name));

% Load whole structure if multiple fields
fnames = fieldnames(s);
if numel(fnames) == 1
    out = s.(fnames{1});
else
    out = s;
end
% Convert datasets to table
if isa(out, 'dataset'), out = dataset2table(out); end
end