function tf = isMicrocap(tb,fname,lag)
% ISMICROCAP Checks which Id - Date pairs are microcaps
%
%   ISMICROCAP(TB) TB is a table with Id, Date (yyyymmdd) and Price 
%
% NOTE: it is true by default for first LAG observations of each ID
%       

if nargin < 3, lag = 1; end

% Ensure it is sorted by Permno and Date
idx = diff(tb.Date) == 0;
if ~all(tb.Permno(idx) ~= tb.Permno([false;idx]))
    [tb,isort] = sortrows(tb,{'Permno','Date'});
    SORT_BACK  = true;
else
    SORT_BACK = false;
end

% Nyse breakpoints (no. of shares are expressed in millions)
try
    bpoints = loadresults('ME_breakpoints_TXT');
catch
    bpoints = loadresults('ME_breakpoints_TXT','..\results');
end
bpoints      = bpoints(ismember(bpoints.Date, unique(tb.Date/100)),{'Date','Var3'});
bpoints.Var3 = [NaN(lag,1); bpoints.Var3(lag+1:end)];

% price filter
tb.IsPriceBelow = [false(lag,1); tb.(fname)(1+lag:end) < 5];

% Get lagged market cap
cap           = getMktCap(tb,lag,false);
[idx,pos]     = ismembIdDate(tb.Permno, tb.Date, cap.Permno,cap.Date);
tb.Cap(idx,1) = cap.Cap(pos(idx));
% Market cap filter versus 1st Nyse decile
[~,pos]       = ismember(tb.Date/100,bpoints.Date);
tb.NyseCap    = bpoints.Var3(pos)*1000;
tb.IsCapBelow = tb.Cap < tb.NyseCap;

% Output
tf = tb.IsPriceBelow | tb.IsCapBelow;

% Permno as grouping label to account for lag
igroup      = [false(lag,1); tb.Permno(1:end-lag) == tb.Permno(1+lag:end)];
tf(~igroup) = true;

if SORT_BACK
    tf(isort) = tf;
end
end