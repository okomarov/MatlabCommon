function tf = issp500member(tb, spconst)
% ISSP500MEMBER Checks which Id - Date pair are sp500 members
%
%   ISSP500MEMBER(TB) TB is a table with Id and yyyymmdd Date 

if isa(tb,'dataset')
    tb = dataset2table(tb);
end
if nargin < 2
    try
        spconst = loadresults('spconst');
    catch
        spconst = loadresults('spconst','..\results');
    end
end
tf = ismembIdDate(tb.Permno, tb.Date, spconst.Permno, spconst.Date);
end