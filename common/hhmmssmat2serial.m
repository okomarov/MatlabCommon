function n = hhmmssmat2serial(hhmmss)
% HHMMSSMAT2SERIAL Converts a matrix with hours, minutes and seconds (1-3rd columns) into a vector of serial timestamps
if ~isa(hhmmss,'double')
    hhmmss = double(hhmmss);
end
n = hhmmss(:,1)/24 + hhmmss(:,1)/1440 + hhmmss(:,1)/86400;
end