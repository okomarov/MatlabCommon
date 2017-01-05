function corrmat = corrxs(panel, names)
% CORRXS Average of cross-sectional correlations
%
%   CORRXS(PANEL) PANEL should be a 3D array where each row is an 
%       observation, each column a variable, and each layer a type
%       of cross-section. 
%       Correlations are taken for each observation by pairing 
%       layers where both are not NaN. 
%       The correlation matrix, is the time-series average
%       of the cross-sectional correlations at each date. 
%
%   CORRXS(...,NAMES) A cell array of NAMES labels the layers and
%       the headers in the resulting correlation matrix
%
%   CORRMAT = ...
%       Correlation matrix with NLAYERS rows/columns and 
%       Pearson correlations in the lower diagonal part and
%       Spearman (rank) correlations in the upper diagonal.
%
% See also: CORR

[nobs,~,nlay] = size(panel);
if nlay == 0
    corrmat = [];
    warning('ARRAY should be a 3D array.');
    return
end

if nargin < 2 || isempty(names)
    names = matlab.internal.table.dfltVarNames(1:nlay);
elseif nlay ~= numel(names)
    error('corrxs:invalidNumNames','NAMES should have one element for each layer in PANEL.')
end

[pears, spear] = deal(zeros(nobs,nlay,nlay)); 
inan           = any(isnan(panel),3);
for ii = 1:nobs
    slice = squeeze(panel(ii,~inan(ii,:),:));
    if isempty(slice)
        continue
    end
    pears(ii,:,:) = corr(slice,'type','Pearson');
    spear(ii,:,:) = corr(slice,'type','Spearman');
end
pears   = squeeze(nanmean(pears));
spear   = squeeze(nanmean(spear));
corrmat = tril(pears,-1) + triu(spear,+1) + diag(NaN(nlay,1));
corrmat = array2table(corrmat, 'VariableNames', names, 'RowNames',names);
end
