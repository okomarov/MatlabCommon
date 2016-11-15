function n = hhmmss2serial(x)
n = datenum(0,0,0, fix(x/1e4), fix(mod(x,1e4)/1e2), mod(x,1e2));
end