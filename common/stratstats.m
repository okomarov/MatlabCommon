function [tbstats, tbarets] = stratstats(dates, ret, varargin)
% [tbstats, tbarets] = stratstats(dates, ret, freq, isperc)
%
%   STRATSTATS(DATES, RET)
%       Calculates several statistics on each column of the RET matrix.
%       DATES can be in 'yyyymmdd' numeric format or in datetime()
%       and must have the same lenght as RET.
%
%   STRATSTATS(..., NAME, VALUE,...)
%       Valid NAME/VALUE pairs are:
%           'Frequency' - 'd' (default) for daily or 'm'  for monthly.
%               Specifies at which frequency are expressed the returns.
%           'IsPercentageReturn' - false (default) or true.
%           'UseSimpleInterest'  - true (default) or false. Alternatively
%               uses compounded return to calculate statistics.
%
%   [TBSTATS, TBARETS] = ...
%       TBSTATS is a table with the following statistics:
%           .Avgret  - mean
%           .Std     - standard deviation (Newey-West robust)
%           .Se      - Newey-West robust standard error with fixed
%                      bandwidth at floor(4*(nobs/100)^(2/9))+1
%           .Pval    - pValue
%           .Annret  - annualized mean return
%           .Annstd  - annualized standard deviation
%           .SR      - Sharpe ratio
%           .Downstd - annualized downside deviation with threshold at 0
%           .Minret  - minimum
%           .Medret  - median
%           .Maxret  - maximum
%           .Skew    - skewness
%           .Kurt    - kurtosis
%           .Mdd     - maximum drawdown, i.e. deepest negative trend
%           .Mddlen  - time from start to end of the MDD
%           .Reclen  - time taken to recover the drawdown. If negative,
%                      then recovery not completed by the end of the data
%           .Sortino - Sortino ratio, i.e. Annret/Downstd

% Parse inputs
p              = inputParser();
p.FunctionName = 'stratstats';

addRequired(p, 'dates')
addRequired(p, 'ret')
addParameter(p,'Frequency', 'd',  @(x) any(validatestring(x,{'d','m'})))
addParameter(p,'IsPercentageReturn', false,@(x) islogical(x) && isscalar(x))
addParameter(p,'UseSimpleInterest', true,@(x) islogical(x) && isscalar(x))

parse(p, dates, ret, varargin{:});

freq   = p.Results.Frequency;
isperc = p.Results.IsPercentageReturn;

if ~isdatetime(dates)
    dates = yyyymmdd2datetime(dates);
end
dates = dates(:);

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
tbstats.Std       = reshape(nanstd(ret),[],1);
tbstats.Se        = se(:);
tbstats.Pval(:,1) = tcdf(-abs(coeff./se),sz(1)-1)*2;
lvl               = ret2lvl(ret,isperc);
if p.Results.UseSimpleInterest
    tbstats.Annret = tbstats.Avgret * scale;
else
    tbstats.Annret = lvl(end,:)'.^(1/years(dates(end)-dates(1)))-1;
end
tbstats.Annstd  = tbstats.Std * sqrt(scale);
tbstats.SR      = tbstats.Annret./tbstats.Annstd;
tbstats.Downstd = sqrt(nanmean(double(ret<=0) .* ret.^2))' * sqrt(scale);
tbstats.Minret  = nanmin(ret)';
tbstats.Medret  = nanmedian(ret)';
tbstats.Maxret  = nanmax(ret)';
tbstats.Skew    = skewness(ret)';
tbstats.Kurt    = kurtosis(ret)';

% Fails if prices go below 0
try
    [mdd,imdd]  = maxdrawdown(lvl);
    tbstats.Mdd = mdd(:)*100^double(isperc);
    if freq == 'd'
        tbstats.Mddlen = days(dates(imdd(end,:))-dates(imdd(1,:)));
    else
        from           = datenum(dates(imdd(1,:)));
        to             = datenum(dates(imdd(end,:)));
        tbstats.Mddlen = months(from,to,1);
    end
    tbstats.Reclen = timeToRecovery(lvl, dates, imdd, freq);
catch
    tbstats.Mdd    = NaN(sz(2),1);
    tbstats.Mddlen = NaN(sz(2),1);
    tbstats.Reclen = NaN(sz(2),1);
end

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
        from       = datenum(dates(imdd(end,ii)));
        to         = datenum(dates(irec));
        reclen(ii) = months(from,to,1);
    end
    if ~hasRecovered
        reclen(ii) = -reclen(ii);
    end
end
end