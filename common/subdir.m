function c = subdir(rootdir)
% SUBDIR List full pathnames to subdirectories
%
%   subdir(rootdir) where ROOTDIR is a valid directory
%
% See also: DIR

% Author: Oleg Komarov, (C) 2017 oleg(dot)komarov(at)hotmail(dot)it
% Tested on R2016b Win7 64bit

if isdir(rootdir)
    s = dir(rootdir);
else
    error('subir:notdir','ROOTDIR is not a directory.');
end
s = s([s.isdir] & ~ismember({s.name},{'.','..'}));

if nargout == 0
    cellfun(@(x) fprintf('%s\n',x), {s.name})
else
    c = {s.name};
end
end
