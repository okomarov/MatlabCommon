function [ptfret, ptfGroup, groupCount] = portfolio_sort(ret, signals, opts)
if isnumeric(signals)
    signals = {signals};
end
if nargin < 3 || isempty(opts)
    opts = struct();
end

[nobs,nseries] = size(ret);

% Extract weights
try
    w = opts.Weights;
catch
    w = [];
end

% Intersect all NaNs
inan = isnan(ret);
for s = 1:numel(signals)
    inan = inan | isnan(signals{s});
end
if ~isempty(w)
    inan = inan | isnan(w);
    w(inan) = NaN;
end
for s = 1:numel(signals)
    signals{s}(inan) = NaN;
end

% Group signals
[ptfGroup, groupCount, ptfId,allbin] = binSignal(signals{:},opts);

% Date-ptf subs
row  = repmat((1:nobs)', 1, nseries);
subs = [row(:), ptfGroup(:)+1];

% Ptf returns as XS averages
% NOTE: avoid nansum/mean to gain a 3-4x speedup
count = accumarray(subs, ~isnan(ret(:)));
if isempty(w)
    ptfret = accumarray(subs, nan2zero(ret(:)))./count;
else
    % Normalize weights at each date by signal group to sum to 1
    wsum   = accumarray(subs, nan2zero(w(:)));
    pos    = sub2ind([nobs,nseries],subs(:,1), subs(:,2));
    wnorm  = w(:)./wsum(pos);
    ptfret = accumarray(subs, nan2zero(ret(:) .* wnorm));
end

% Fill NaNs
inan         = ~logical(count);
ptfret(inan) = NaN;

% Drop null-indexed ptf
ptfret = ptfret(:,2:end);
end