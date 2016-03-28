function [tb,imiss,pos] = lagpanel(tb,idname,lag)
% LAGPANEL Lags a vertically-stacked dataset of time-series (panel)
%
%   LAGPANEL(TB, IDNAME, [LAG])
%       TB should have an id whose name is specified in IDNAME
%       and a Date in yyyymmdd format. Time-series should be
%       shorted in ascending order by id-date.
%       LAG should be a positive integer (default: 1)
narginchk(2,3)
if nargin < 3
    lag = 1;
elseif isempty(lag) || lag == 0
    imiss = [];
    pos   = [];
    return
end

% If negative date change correponds to same id then not sorted
if ~issortedpanel(tb,'Permno')
    error('lagpanel:notSorted','TB should be sorted in ascending order by id-date.')
end

id    = int64(tb.(idname));
imiss = [true(lag,1); id(1+lag:end) - id(1:end-lag) ~= 0];

% Lag each variable
vnames = setdiff(tb.Properties.VariableNames, {'Date', idname});
for ii = 1:numel(vnames)
    v = vnames{ii};

    tb.(v)(1+lag:end) = tb.(v)(1:end-lag);
    try
        tb.(v)(imiss) = NaN;
    catch
        tb.(v)(imiss) = 0;
    end
end

if nargout == 3
    pos = find(~imiss(1+lag:end));
end
end
