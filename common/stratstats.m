function [tbstats, tbarets] = stratstats(dates, ret, freq, isperc)
% [tbstats, tbarets] = stratstats(dates, ret, freq, isperc)

if nargin < 3 || isempty(freq)
    freq = 'd';
end
if nargin < 4 || isempty(isperc)
    isperc = false;
end
if ~isdatetime(dates)
    dates = yyyymmdd2datetime(dates);
end

% Annualizing factor 
switch freq
    case 'd'
        scale = 252;
    case 'm'
        scale = 12;
end

% Add day preceding first
if numel(dates) == size(ret,1)
    first = dates(1);
    switch freq
        case 'd'
            dates = [datetime(year(first),month(first),day(first)-1); dates];
        case 'm'
            dates = [datetime(year(first),month(first),0); dates];
    end
end

% Standard NW errors
sz           = size(ret);
opts         = {'bandwidth',floor(4*(sz(1)/100)^(2/9))+1,'weights','BT','intercept',false,'display','off'};
fun          = @(x) hac(ones(sz(1),1), ret(:,x),opts{:});
[~,se,coeff] = arrayfun(fun,1:sz(2));

% Stats
tbstats           = table();
tbstats.Avgret    = coeff(:);
tbstats.Se        = se(:);
tbstats.Pval(:,1) = tcdf(-abs(coeff./se),sz(1)-1)*2; 
lvl               = ret2lvl(ret,isperc);
tbstats.Annret    = lvl(end,:)'.^(1/years(dates(end)-dates(1)))-1;
tbstats.Annstd    = nanstd(ret)'*sqrt(scale);
tbstats.Downstd   = nanstd(ret > 0 .* ret)' * sqrt(scale);
tbstats.Minret    = nanmin(ret)';
tbstats.Medret    = nanmedian(ret)';
tbstats.Maxret    = nanmax(ret)';
tbstats.Skew      = skewness(ret)';
tbstats.Kurt      = kurtosis(ret)';
tbstats.SR        = tbstats.Annret./tbstats.Annstd;
[mdd,imdd]        = maxdrawdown(lvl);
tbstats.Mdd       = mdd(:);
if freq == 'd'
    tbstats.Mddlen = days(dates(imdd(end,:))-dates(imdd(1,:)));
else
    tbstats.Mddlen = months(dates(imdd(1,:)),dates(imdd(end,:)),1);
end
tbstats.Reclen  = timeToRecovery(lvl, dates, imdd, freq);
tbstats.Sortino = tbstats.Annret./tbstats.Downstd;

if nargout == 2
    tbarets = level2arets(lvl,dates);
end
end

function lvl = ret2lvl(ret,isperc)
if isperc
    ret = ret/100;
end
inan      = isnan(ret);
ret(inan) = 0;
from      = find(~inan,1,'first')-1;
c         = size(ret,2);
lvl       = [NaN(from-1,c); 
             cumprod([ones(1,c); ret(from+1:end,:)+1])];
end

function arets = level2arets(lvl,dates)
sz    = size(lvl);
rsub  = repmat(cumsum([1; logical(diff(year(dates)))]), 1, sz(2));
csub  = repmat(1:sz(2),sz(1),1);
arets = accumarray([rsub(:),csub(:)],lvl(:), [],@(x) x(end)./x(1)-1); 
end

function reclen = timeToRecovery(lvl,dates, imdd, freq)
[nobs,nser] = size(lvl);
reclen      = zeros(nser,1);

for ii = 1:nser
    hasRecovered = true;
    ddpeak       = lvl(imdd(1,ii),ii);
    residLvl     = lvl(imdd(end,ii)+1:end,ii);
    irec         = imdd(end,ii) + find(residLvl >= ddpeak,1,'first');
    if isempty(irec)
        hasRecovered = false;
        irec         = nobs;
    end
    if freq == 'd'
        reclen(ii) = days(dates(irec)-dates(imdd(end,ii)));
    else
        reclen(ii) = months(dates(imdd(end,ii)),dates(irec),1);
    end
    if ~hasRecovered
        reclen(ii) = -reclen(ii);
    end
end
end