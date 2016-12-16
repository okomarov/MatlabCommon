function [bins, counts, ptf_id, allbins] = binSignal(varargin)
% BINSIGNAL Sort cross-section of signals into percentile or custom bins
%
%   BINSIGNAL(SIGNAL, OPTS) Group SIGNALs according to its row-wise percentiles
%
%                     OPTS.() is a structure that can have the following
%                     exatc fields (defaults on the right):
%
%                         .IndependentSort - True
%                         .PortfolioNumber - 5
%                         .PortfolioEdges  - [], prevails on PortfolioNumber
%
%                     NOTE:
%                       * With IndependentSort, the composite group is
%                         the intersection of each signal's groups.
%                         Otherwise, the ORDER of signals matter, i.e. a
%                         set of groups is formed from the first signal,
%                         and intra-groups are subsequently created
%                         according to the signals that follow (conditional
%                         binning). The composite group is the finest
%                         intra-group.
%
%                       * The PortfolioNumber at each date splits the cross
%                         section into equally populated groups. It uses the
%                         prctile() function to create PortfolioEdges.
%
%                       * You can pass ad hoc breakpoints as
%                         PortfolioEdges.
%
%   [BINS, COUNTD, PTF_ID, ALLBINS] = BINSIGNAL(...)

[opts, signals] = parseInputs(varargin{:});

% Perform binning and counts
if opts.IndependentSort
    [bins, counts, ptf_id, allbins] = binIndipendently(signals, opts);
else
    [bins, counts, ptf_id, allbins] = binConditionally(signals, opts);
end
end

% INDIPENDENT binning
function [compbin, counts, ptf_id, bin] = binIndipendently(signals, opts)
[nobs, nser, nsig] = size(signals);
bin                = zeros(nobs, nser, nsig);
ptf_id             = cell(nsig,1);

% Sequential indipendent binning
for s = 1:nsig
    [bin(:,:,s), N, ptf_id{s}] = binCore(signals(:,:,s),s,opts);
    % TODO: adjust N boundary cases
end

% Map ptf combinations into progressive IDs
if nsig > 1
    [compbin,counts,ptf_id] = mapPtfId(bin,ptf_id);
else
    compbin = bin;
    counts  = N;
    ptf_id  = ptf_id{1}(:);
end
end

% CONDITIONAL binning
function [compbin, counts, ptf_id, bin] = binConditionally(signals, opts)
[nobs, nser, nsig] = size(signals);
bin                = zeros(nobs, nser, nsig);
ptf_id             = cell(nsig,1);

% Bin the first signal
[bin(:,:,1),~,ptf_id{1}] = binCore(signals(:,:,1), 1, opts);

% Bin portion of signal conditional on ptf number from previous signal
for s = 1:nsig-1
    curr_signal = signals(:,:,s+1);
    prev_signal = bin(:,:,s);
    for id = ptf_id{s}(:)'
        tmpsig                 = curr_signal;
        ibin                   = prev_signal == id;
        tmpsig(~ibin)          = NaN;
        [tmpbin,~,ptf_id{s+1}] = binCore(tmpsig, s+1, opts);
        bin(:,:,s+1)           = bin(:,:,s+1) + tmpbin;
    end
end

% Map ptf combinations into progressive IDs
if nsig > 1
    [compbin,counts,ptf_id] = mapPtfId(bin,ptf_id);
else
    compbin = bin;
    counts  = N;
    ptf_id  = ptf_id{1};
end
end

% CORE binning algo
function [bin, N, id] = binCore(data, idx, opts)
[nobs,nser] = size(data);

% Get Edges
if opts.HasEdges(idx)
    edges = opts.PortfolioEdges{idx};
else
    try
        numptfs = opts.PortfolioNumber(idx);
    catch
        numptfs = opts.PortfolioNumber(1);
    end
    p     = linspace(0,100,numptfs+1);
    edges = prctile(data,p,2);
end

% Portfolio IDs
numptf = size(edges,2)-1;
id     = 1:numptf;

% Actual binning
if isrow(edges)
    [N,~,bin] = histcounts(data, edges);
else
    N    = zeros(nobs, numptf);
    bin  = zeros(nobs, nser);
    inan = all(isnan(edges),2);
    for r = 1:nobs
        if ~inan(r)
            try
                [N(r,:),~,bin(r,:)] = histcounts(data(r,:), edges(r,:));
            catch
                [mdata, medges]     = getMonotonicEdges(data(r,:),nser,p);
                [N(r,:),~,bin(r,:)] = histcounts(mdata, medges);
            end
        end
    end
end
end

function [data, edges] = getMonotonicEdges(data,nser,p)
% Ensure percentiles are monotonically increasing by calculating
% them on position of sorted data. Data is then replaced by the positions.
[~,col]          = sort(data,2);
col(col)         = 1:nser;
col(isnan(data)) = NaN;
edges            = prctile(col,p,2);
data             = col;
end

function [compbin,counts,ptf_id] = mapPtfId(bin,ptf_id)
[nobs,nser,nsig] = size(bin);
[ptf_id{1:nsig}] = ndgrid(ptf_id{:});
ptf_id           = cellfun(@(x) x(:),ptf_id,'un',0);
ptf_id           = [ptf_id{:}];

% The mapping is: max(other_layers-1, 0) * groupsize(1:last-1) + first_layer;
other_layers = bin(:,:,end:-1:2);
gsize        = reshape(ptf_id(end,end-1:-1:1),1,1,nsig-1);
compbin      = max(other_layers-1,0) * gsize  +  bin(:,:,1);
row          = repmat((1:nobs)',1,nser);
idx          = compbin > 0;
counts       = accumarray([row(idx), compbin(idx)+1],1);
counts       = counts(:,2:end);
% % Equivalently (but slower)
% numid            = size(ptf_id,1);
% compbin          = zeros(nobs,nser);
% counts           = zeros(nobs,numid);
% for id = 1:numid
%     combination  = reshape(ptf_id(id,:),1,1,nsig);
%     idx          = all(bsxfun(@eq, bin, combination),3);
%     compbin(idx) = id;
%     counts(:,id) = sum(idx,2);
% end
end

function [opts, signals] = parseInputs(varargin)
if nargin == 1
    varargin = [varargin, struct()];
end
varargin = varargin(:);

% Options can be name/value pairs OR a struct
istruct       = cellfun(@isstruct, varargin);
isOptsStruct  = any(istruct);
iopts         = cellfun(@ischar,varargin);
isOptsNameVal = any(iopts);
if isOptsStruct && isOptsNameVal
    error('binSignal:invalidOpts','OPTIONS should come as name/value pairs or as a structure, not both.')
elseif isOptsNameVal
    % Convert name/value pairs to struct
    pos          = find(iopts);
    suppliedOpt  = cell2struct(varargin(pos+1),varargin(pos));
    iopts(pos+1) = true;
    isignal      = ~iopts;
else
    suppliedOpt = varargin{istruct};
    isignal     = ~istruct;
end

% Concatenate signals
try
    signals = cat(3,varargin{isignal});
catch
    error('binPortfolios:invalidSignals','SIGNALS must have the same dimensions.')
end

% Defaults options
opts = struct('IndependentSort', true    ,...
              'PortfolioNumber', 5       ,...
              'PortfolioEdges' , {{[]}}  );

% Overwrite with supplied options
for f = fieldnames(suppliedOpt)'
    if isfield(opts, f)
        opts.(f{1}) = suppliedOpt.(f{1});
    else
        warning('binPortfolios:unrecognizedOption','Unrecognized option "%s".',f{1})
    end
end
opts.HasEdges = ~cellfun(@isempty,opts.PortfolioEdges);
nsig = size(signals,3);
if numel(opts.HasEdges) ~= nsig
    error('binPortfolios:missingEdges','Provide a cell array with a set of ''PortfolioEdges'' for each signal. When empty ''PortfolioNumber'' is used.')
end
if numel(opts.PortfolioNumber) ~= nsig
    error('binPortfolios:missingPtfNum','Provide ''PortfolioNumber'' for each signal.')
end
end