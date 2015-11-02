function [cov, se, coeff] = nwse(data, opts)
% NWSE Newey-West standard errors for each column

sz = size(data);
if nargin < 2
    opts = {'bandwidth',floor(4*(sz(1)/100)^(2/9))+1,'weights','BT','intercept',false,'display','off'};
end

fun            = @(x) hac(ones(sz(1),1), data(:,x), opts{:});
[cov,se,coeff] = arrayfun(fun,1:sz(2));
end