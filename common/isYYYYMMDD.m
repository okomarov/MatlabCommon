function bool = isYYYYMMDD(date)
% ISYYYYMMDD Checks that date is in numeric YYYYMMDD format

bool = isnumeric(date) && all(mod(date,1) == 0) && all(in(date, [0,99999999]));
end
