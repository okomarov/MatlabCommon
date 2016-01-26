function [h,p,z] = sharpetest(x,y,M,alpha,tail)
% SHARPETEST Test difference in the Sharpe Ratios (SR) of two assets
%
%   SHARPETEST(X,Y)
%       Test the null hypothesis that the SR of asset X is bigger than that
%       of asset Y.
%       X and Y must be same-size vectors of returns.
%
%   SHARPETEST(..., M, ALPHA, TAIL)
%       M     - corrects the degrees of freedom by the number of
%               overlapping periods. (default = 0)
%       ALPHA - significance level of the hypothesis test. Must have a
%               value in (0,1). (default = 0.05)
%       TAIL  - type of alternative hypothesis to evaluate. Must be one of
%               one of 'both', 'left' or 'right'. (default = 'right')
%
%   [H,P,Z] = ...
%       H - hypothesis test result, 1 for rejection of the null at the
%           ALPHA significance level.
%       P - p-value of the statistic
%       Z - the Jobson-Korkie statistic
%
% References:
%   DeMiguel, Garlappi and Uppal, "Optimal versus Naive Diversification. How
%       Inefficient Is the 1/N Portfolio Strategy?", Review of Financial
%       Studies (2009)
%   Jobson and Korkie, "Performance Hypothesis Testing with the Sharpe and
%       Treynor Measures", Journal of Finance (1981)
%
% See also: TTEST

if size(x) ~= size(y)
    error('sharpetest:dimensionMismatch','X and Y must have same dimensions.')
end
if nargin < 3 || isempty(M)
    M = 0;
end
if nargin < 4 || isempty(alpha)
    alpha = 0.05;
end
if nargin < 5
    tail = 'right';
else
    cases = {'left','right','both'};
    idx   = strncmpi(tail,cases,numel(tail));
    tail  = cases{idx};
end
if isempty(tail)
    error('sharpetest:invalidParam','TAIL must be one of ''both'', ''left'' or ''right''.')
end

T     = size(x,1);
s2_x  = nanvar(x);
s2_y  = nanvar(y);
s_x   = sqrt(s2_x);
s_y   = sqrt(s2_y);
mu_x  = nanmean(x);
mu_y  = nanmean(y);
s_xy  = nancov(x,y);
s_xy  = s_xy(2);
df    = T-M;
theta = 1/df*(2*s2_x*s2_y - 2*s_x*s_y*s_xy +...
              0.5*mu_x^2*s2_y + 0.5*mu_y^2*s2_x - ...
              mu_x*mu_y*s_xy^2/(s_x*s_y));

z = (s_y*mu_x - s_x*mu_y)/sqrt(theta);

switch tail
    case 'right'
        p = tcdf(-z, df);
    case 'left'
        p = tcdf(z, df);
    case 'both'
        p = 2 * tcdf(-abs(z), df);
end

h           = cast(p <= alpha, 'like', p);
h(isnan(p)) = NaN;
end
