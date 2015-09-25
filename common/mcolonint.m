function idx = mcolonint(from, to)
% MCOLONINT Colon for multiple from and to subscripts
%
% NOTE: only supports whole from/to and the step size is 1.

nobs     = to-from+1;
idx      = ones(sum(nobs),1);
pos      = cumsum(nobs(1:end-1))+1;
df       = from(2:end) - to(1:end-1);
idx(pos) = df;
idx(1)   = from(1);
idx      = cumsum(idx);
end