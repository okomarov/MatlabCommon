function tf = isMicrocap(tb,lag,crsp,cap)
% ISMICROCAP Checks which Id - Date pairs are microcaps
%
%   ISMICROCAP(TB) TB is a table with Id, Date (yyyymmdd) and Price 
%
% NOTE: it is true by default for first LAG observations of each ID
%       

if nargin < 2, lag = 1; end

% CRSP close prices
if nargin < 3
    try
        crsp = loadresults('dsfquery');
    catch
        crsp = loadresults('dsfquery','..\results');
    end
end

% CRSP market capitalizations (no. of shares are expressed in thousands)
if nargin < 4
    try
        cap = loadresults('mktcap');
    catch
        cap = loadresults('mktcap','..\results');
    end
end

% Nyse breakpoints (no. of shares are expressed in millions)
try
    bpoints = loadresults('ME_breakpoints_TXT');
catch
    bpoints = loadresults('ME_breakpoints_TXT','..\results');
end
bpoints      = bpoints(ismember(bpoints.Date, unique(tb.Date/100)),{'Date','Var3'});
bpoints.Var3 = [NaN(lag,1); bpoints.Var3(lag+1:end)];

% Sort
[tb, isort] = sortrows(tb,{'Permno','Date'});

% Permno as grouping label to account for lag
igroup = [false(lag,1); tb.Permno(1:end-lag) == tb.Permno(1+lag:end)];

% price filter
[idx,pos] = ismembIdDate(tb.Permno, tb.Date, crsp.Permno,crsp.Date);
price     = crsp.Prc(pos(idx));
iprice    = [false(lag,1); price(1+lag:end) < 5];

% Mkt cap filter
[~,pos]   = ismember(tb.Date/100,bpoints.Date);
nyseCap   = bpoints.Var3(pos)*1000;
[idx,pos] = ismembIdDate(tb.Permno, tb.Date, cap.Permno,cap.Date);
cap       = cap.Cap(pos(idx));
icap      = [inf(lag,1); cap(1+lag:end)]  < nyseCap;

tf          = iprice | icap;
tf(~igroup) = true;
tf(isort)   = tf;
end