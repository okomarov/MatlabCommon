function idx = in(A, bounds, inclusion)
% idx = in(A, bounds, inclusion)
if isempty(bounds)
    idx = true(numel(A),1);
    return
end

if iscell(bounds)
    idx = false(numel(A),1);
    for ii = 1:numel(bounds)
        idx = idx | in(A,bounds{ii},inclusion);
    end
    return
end

if numel(bounds) < 2
    error('in:numBounds','BOUNDS should have two dates, i.e [from, to].')
end
bounds = sort(bounds,2);

if nargin < 3 || isempty(inclusion)
    inclusion = '[]';
elseif ~ischar(inclusion)
    error('in:inclusionType','INCLUSION should be char.')
end

lb = bounds(:,1);
ub = bounds(:,2);
switch inclusion
    case '[]'
        idx = lb <= A & A <= ub;
    case '()'
        idx = lb <  A & A <  ub;
    case '[)'
        idx = lb <= A & A <  ub;
    case '(]'
        idx = lb <  A & A <= ub;
    otherwise
        error('Invalid INCLUSION, can be "[]","[)","(]" or "()".')
end
end
