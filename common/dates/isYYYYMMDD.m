function bool = isYYYYMMDD(date)
% ISYYYYMMDD Checks that date is in numeric YYYYMMDD format
if isnumeric(date)
    bool = mod(date,1) == 0 & in(date, [0,99999999]);
else
    bool = false;
end
end
