function [ptfret, ptfGroup, groupCount, avgSignal] = portfolio_sort(ret, signals, varargin)
% PORTFOLIO_SORT Get return series of percentile-sorted portfolios
%
%   PORTFOLIO_SORT(RET, SIGNALS)
%       SIGNALS and RET are same-size matrices where rows denote the
%       time dimension and columns the cross-sectional dimension.
%       SIGNALS are binned by percentile on each date and the intra-bin
%       average returns are calculated.
%
%   PORTFOLIO_SORT(..., OPTS or Name/Value pairs)
%       OPTS.() is a structure that can have the following exact fields
%       (defaults on the right):
%           .Weights         - equal weighted
%           .IndependentSort - True
%           .PortfolioNumber - 5
%           .PortfolioEdges  - [], prevails on PortfolioNumber
%
%   [PTFRET, PTFGROUP, GROUPCOUNT, AVGSIGNAL] = ...
%
% See also: BINSIGNAL

if isnumeric(signals)
    signals = {signals};
end
if nargin < 3
    opts = struct();
elseif nargin == 3 && isstruct(varargin{1})
    opts = varargin{1};
else
    opts = cell2struct(varargin(2:2:end), varargin(1:2:end),2);
end

[nobs,nseries] = size(ret);
if ~all(nobs == cellfun('size', signals,1)) || ...
   ~all(nseries == cellfun('size', signals,2))
    error('portfolio_sort:sizeMismatch','SIGNALS must have same size as RET.')
end

% Extract weights
try
    w    = opts.Weights;
    opts = rmfield(opts, 'Weights');
catch
    w = [];
end

% Intersect all NaNs
inan = isnan(ret);
nsig = numel(signals);
for s = 1:nsig
    inan = inan | isnan(signals{s});
end
if ~isempty(w)
    inan    = inan | isnan(w);
    w(inan) = NaN;
end
for s = 1:nsig
    signals{s}(inan) = NaN;
end

% Group signals
[ptfGroup, groupCount, ptfId,allbin] = binSignal(signals{:},opts);

% Date-ptf subs
row  = repmat((1:nobs)', 1, nseries);
subs = [row(:), ptfGroup(:)+1];

% Ptf returns as XS averages
% NOTE: 
%   * avoid nansum/mean to gain a 3-4x speedup
%   * this count has counts for the null group
%   * the null group might have values after nan intersecting signals
count = accumarray(subs, ~isnan(ret(:)));
if isempty(w)
    ptfret = accumarray(subs, nan2zero(ret(:)))./count;
else
    % Normalize weights at each date by signal group to sum to 1
    wsum   = accumarray(subs, nan2zero(w(:)));
    wsum   = wsum(:);
    pos    = sub2ind([nobs,nseries],subs(:,1), subs(:,2));
    wnorm  = w(:)./wsum(pos);
    ptfret = accumarray(subs, nan2zero(ret(:) .* wnorm));
end

% Fill NaNs
inan         = ~logical(count);
ptfret(inan) = NaN;

% Drop null-indexed ptf
ptfret = ptfret(:,2:end);

% Average of signals
if nargout == 4
    avgSignal = NaN(nobs,max(prod(ptfId,2))+1,nsig);
    for s = 1:nsig
        if isempty(w)
            avgSignal(:,:,s) = accumarray(subs, nan2zero(signals{s}(:)))./count;
        else
            avgSignal(:,:,s) = accumarray(subs, nan2zero(signals{s}(:) .* wnorm));
        end
    end
    avgSignal = avgSignal(:,2:end,:);
end
end