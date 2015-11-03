function idx = mcolonint(from, to)
% MCOLONINT Colon for multiple from and to subscripts
%
% NOTE: only supports whole from/to and the step size is 1.

oldclass = class(to);
from     = int64(from);
to       = int64(to);

nobs     = to-from+1;
idx      = ones(sum(nobs),1);
pos      = [1; cumsum(nobs(1:end-1))+1];
df       = [from(1); from(2:end) - to(1:end-1)];
idx(pos) = df;
idx      = cumsum(idx);

idx = cast(idx,oldclass);
end