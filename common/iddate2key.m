function key = iddate2key(id,date)
% IDDATE2KEY Creates a key from id and date as ###yyyymmdd
key = uint64(id)*1e8 + uint64(date);
end
