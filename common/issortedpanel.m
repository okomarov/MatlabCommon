function bool = issortedpanel(tb, idname)
% ISSORTEDPANEL Check if a panel is sorted by id and ascending date
%
% A panel is a vertically-stacked dataset of time-series

% If negative date change correponds to same id then not sorted
idx  = diff(int64(tb.Date)) < 0;
id   = tb.(idname);
bool = ~(any(id(idx) == id([false;idx])) || any(diff(int64(id)) < 0));
end
