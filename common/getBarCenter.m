function x = getBarCenter(h)
% GETBARCENTER Find center of a grouped bar
%
%   In a grouped barplot there are several adjacent bars in a group
%   and each belongs to a different bar series. This function retrieves
%   the center on the x-axis for each bar of a specific seris (across  
%   groups). It does not retrieve the centers of a specific group.
style = get(h,'BarLayout');

switch style
    case 'grouped'
        barPeers     = get(h,'BarPeers');
        barPeers     = barPeers(end:-1:1); % Get plotting order
        [~, thisBar] = ismember(h, barPeers);
        barsInGroup  = numel(barPeers);
        numGroups    = size(get(h,'XData'),2);
        groupWidth   = min(0.8, barsInGroup/(barsInGroup+1.5));
        x            = (1:numGroups) - groupWidth/2 + (2*thisBar - 1) * groupWidth / (2*barsInGroup);
    otherwise
end
end
