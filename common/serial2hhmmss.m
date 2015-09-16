function x = serial2hhmmss(n)
% SERIAL2HHMMSS Convert serial time to HHMMSS format
%
% NOTE: discards date
x = datevec(n);
x = x(:,4:end)*[10000;100;1];
end