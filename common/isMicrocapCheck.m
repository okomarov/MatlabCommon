function crsp = isMicrocapCheck(permno, date, crsp, cap)

% Load crsp prices and market cap
% 
% try
%     crsp = loadresults('dsfquery');
% catch
%     crsp = loadresults('dsfquery','..\results');
% end
%
% try
%     cap = loadresults('mktcap');
% catch
%     cap = loadresults('mktcap','..\results');
% end

lag  = 1;
lagf = @(x) [NaN(lag,1); x(lag+1:end)];

% Filter permno
crsp = sortrows(crsp(ismember(crsp.Permno, permno),:),'Date');
cap  = sortrows(cap (ismember(cap.Permno,  permno),:),'Date');

% Filter previous date
crsp.Prc = lagf(crsp.Prc);
cap.Cap  = lagf(cap.Cap);

% Add capitalization
[~,pos]  = ismembIdDate(crsp.Permno, crsp.Date, cap.Permno, cap.Date);
crsp.Cap = cap.Cap(pos);

% Filter date
if isempty(date)
    date = unique(crsp.Date);
else
    crsp = crsp(ismember(crsp.Date, date),:);
end

% Nyse breakpoints (no. of shares are expressed in millions)
try
    bpoints = loadresults('ME_breakpoints_TXT');
catch
    bpoints = loadresults('ME_breakpoints_TXT','..\results');
end
bpoints.Var3 = lagf(bpoints.Var3); 
bpoints      = bpoints(ismember(bpoints.Date, date/100),{'Date','Var3'});

% Add nyse cap
[~,pos]      = ismember(crsp.Date/100,bpoints.Date);
crsp.NyseCap = bpoints.Var3(pos)*1000;

% Conditions
crsp.IsPriceBelow = crsp.Prc < 5;
crsp.IsCapBelow   = crsp.Cap < crsp.NyseCap;

crsp = crsp(:,{'Permno','Date','Prc','IsPriceBelow','Cap','NyseCap','IsCapBelow'});
end