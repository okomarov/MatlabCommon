function wssize(varargin)

% WSSIZE Display in the command window the size of the variables in the workspace using KB, MB and GB
%
%   WSSIZE Display preserving the order of the workspace pane using mixed units
%
%   WSSIZE arg or WSSIZE('arg') One argument syntax
%   WSSIZE arg1 arg2 or WSSIZE('arg1','arg2') Two arguments syntax
%       - arguments: should be char; max two arguments are allowed.
%                    Arguments are not case-sensitive.
%
%   There are two types of arguments.
%       - Sorting methods:
%               'name'   -  sort by name in ascending order. Not case sensitive.
%               '-name'  -  sort by name in descending order. Not case sensitive.
%               'size'   -  sort from smallest to biggest.
%               '-size'  -  sort from biggest to smallest.
%               '-'      -  simply reverse workspace pane order.
%
%       - Display units:
%               'KB'     -  kilobytes
%               'MB'     -  megabytes
%               'GB'     -  gigabytes
%
%   The order of the two types of arguments doesn't matter. Shortened arguments
%   can be supplied ('s' instead of 'size').
%
% Examples:
%   - wssize                    % Display preserving the order of the workspace pane
%       MyVar2 :   63.281 KB
%       myVar  :   19.531 KB
%       myVar1 :   78.125 KB
%       ====================
%       T      :  160.938 KB
%
%   - wssize s MB               % Display ordering from smallest to biggest using MB
%   - wssize('MB','size')       % Equivalent syntax
%       myVar  :    0.019 MB
%       MyVar2 :    0.062 MB
%       myVar1 :    0.076 MB
%       ====================
%       T      :    0.157 MB
%
%   - wssize -name              % Display by not case-sensitive alphabetical desc order
%   - wssize('-name')           % Equivalent syntax
%       MyVar2 :   63.281 KB
%       myVar1 :   78.125 KB
%       myVar  :   19.531 KB
%       ====================
%       T      :  160.938 KB
%
% Additional features:
% - <a href="matlab: web('http://www.mathworks.com/matlabcentral/fileexchange/26250-display-ws-variables-size-in-b-kb-mb-or-gb','-browser')">FEX wssize page</a>
% - <a href="matlab: web('http://www.mathworks.com/matlabcentral/newsreader/view_thread/269361#705343','-browser')">Thread on Newsgroup</a>
% - <a href="matlab: web('http://UndocumentedMatlab.com/blog/customizing-matlabs-workspace-table/','-browser')">Yair's java customization</a>
%
% See also: WHOS, EVALIN

% Original idea by Bastiaan Zuurendonk, TMW technical support engineer
% Author: Oleg Komarov (oleg.komarov@hotmail.it)
% Tested on R14SP3 (7.1) and on R2009b
% 02 jan 2010 - Created from service support answer
% 05 jan 2010 - Edited description; Added sorting by not case-sensitive name and more additional features; Aknowledgments for Bastiaan Zuurendonk
% 06 jan 2010 - Added reverse sorting and unit selection on suggestion by Yair Altman. Edited help
% 07 jan 2010 - Evalin from 'base' to 'caller'
% 15 jan 2010 - Now 'size' sorts from smallest to biggest. Suggestion by Andy.
% 21 jan 2010 - Added 'See also' line.
% 19 feb 2010 - Per Michael suggestion added grand total at the bottom. Restructured code.

% Ninput
narginchk(0,2)

% Get inputs (if any)
if iscellstr(varargin)
    [Unit, Sortby, revsort] = getoptionals(varargin{:});
else
    error('wssize:cellstring','Optional inputs must be char');
end

% Obtain workspace contents
ws_contents = evalin('caller', 'whos');

% If no vars, end the function
if isempty(ws_contents)
    return 
end

% Names and sizes
Names = {ws_contents.name}.';
Sizes = cat(1,ws_contents.bytes);

% Sort by size or name
switch Sortby
    case 'name'
        [trash, IDX] = sort(lower(Names)); %#ok
        Sizes = Sizes(IDX); Names = Names(IDX);
    case 'size'
        [Sizes, IDX] = sort(Sizes,'ascend');
        Names = Names(IDX);
end

if revsort
    Names = flipud(Names);
    Sizes = flipud(Sizes);
end

% Set format according to the longest name + 1
maxNameLength = max(cellfun('prodofsize', Names)) + 1;
fmt = ['%-' num2str(maxNameLength) 's: %12.2f '];

printMemtoScreen(Names, Sizes,fmt, Unit)

% Print grand total (if several variables)
if numel(Sizes) > 1
    allLineLength = maxNameLength + 17;
    fprintf([repmat('=',1,allLineLength) '\n'])
    printMemtoScreen({'T'}, sum(Sizes),fmt, Unit)
end

% Newline for distance
fprintf('\n');

end % wssize

function [Unit,Sortby,revsort] = getoptionals(varargin)

% Default parameters
Unit = ''; Sortby = ''; revsort = false;
% Define units and sorting methods
whichUnit   = {'kb','mb','gb'};
whichSortby = {'-size','-name','size','name'};

% LOOP through each optional argument
for c = 1:numel(varargin)
    % Is it a Unit or a sorting method
    isUnit = strncmpi(varargin{c}, whichUnit,numel(varargin{c}));
    isSortby = find(strncmpi(varargin{c},whichSortby,numel(varargin{c})));

    % IF matches a unit...
    if any(isUnit)
        % ...and is not yet assigned
        if isempty(Unit)
            Unit = whichUnit{isUnit};
        else
            error('wssize:tooUnits','Only one unit of measure should be supplied');
        end
    % IF matches a sorting method...
    elseif ~isempty(isSortby)
        % ...and is not yet assigned
        if isempty(Sortby) && ~revsort
            % IF two matches, then it is just reverse order ('-')
            if numel(isSortby) == 2
                revsort = true;  Sortby = '';
            % reverse by size or name
            elseif isSortby < 3
                    revsort = true;  Sortby = whichSortby{isSortby + 2}; 
            % just by size or name
            else
                Sortby = whichSortby{isSortby};
            end
        else
            error('wssize:tooSort','Only one sorting method should be supplied');
        end
    else
        error('wssize:unrecArg','Argument ''%s'' not recognized',varargin{c});
    end
end

end % getoptionals

% Main engine which prints to the screen the memory used by variables
function printMemtoScreen(Names, Sizes, fmt, Unit)

numVars = numel(Names);

switch Unit
    case 'kb'
        for ii = 1:numVars
            fprintf([fmt 'KB\n'], Names{ii}, Sizes(ii)/1024);
        end
    case 'mb'
        for ii = 1:numVars
            fprintf([fmt 'MB\n'], Names{ii}, Sizes(ii)/1024^2);
        end
    case 'gb'
        for ii = 1:numVars
            fprintf([fmt 'GB\n'], Names{ii}, Sizes(ii)/1024^3);
        end
        
    % Display with mixed units
    otherwise   
        for ii = 1:numVars
            cur_size = Sizes(ii);
            if cur_size < 1025
                fprintf([fmt ' B\n'], Names{ii}, cur_size);
            elseif cur_size < 1024^2+1
                fprintf([fmt 'KB\n'], Names{ii}, cur_size/1024);
            elseif cur_size < 1024^3+1
                fprintf([fmt 'MB\n'], Names{ii}, cur_size/1024^2);
            else
                fprintf([fmt 'GB\n'], Names{ii}, cur_size/1024^3);
            end
        end
end

end % printMemtoScreen