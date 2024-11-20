function [figHandles, unitTable] = plotUnitZScoreHeatmap(cellDataStruct, figureFolder, varargin)
% PLOTUNITZSCOREHEATMAP Creates heatmaps and Cohen's d plots for neural unit responses
%
% This function creates two visualizations of neural unit responses:
% 1. A Cohen's d effect size plot showing the magnitude of unit responses
% 2. A Z-score heatmap showing the temporal dynamics of unit responses
%
% Both plots are organized by experimental group (EMX and PVALB) and sorted by
% effect size (Cohen's d) within each group.
%
% Inputs:
%   cellDataStruct - Structure containing neural recording data with fields:
%       .psthZScore - Z-scored PSTH data
%       .responseMetrics - Response statistics including Cohen's d
%       .responseType - Unit response classification
%       .IsSingleUnit - Boolean indicating if unit is single-unit
%
%   figureFolder - String, path to save output figures
%
%   Name-Value Pair Arguments:
%       'UnitFilter' - String, 'both'|'single'|'multi', default: 'both'
%           Filter for unit type selection
%
%       'OutlierFilter' - Logical, default: true
%           Whether to exclude outlier units
%
%       'ColorLimits' - [min max], default: [-2 2]
%           Z-score color limits for heatmap
%
%       'FontSize' - Numeric, default: 10
%           Base font size for plot text
%
% Outputs:
%   figHandles - Array of figure handles [Cohen's d plot, Heatmap]
%
%   unitTable - Table containing unit statistics:
%       .UnitID - Unit identifier
%       .Group - Experimental group (EMX/PVALB)
%       .CohensD - Effect size measure
%       .CI_Pre - Confidence interval for pre-treatment period [lower upper]
%       .CI_Post - Confidence interval for post-treatment period [lower upper]
%       .ResponseType - Unit response classification
%       .Subtype - Response subtype classification
%
% Example:
%   [figs, stats] = plotUnitZScoreHeatmap(data, './figures', ...
%                   'UnitFilter', 'single', 'ColorLimits', [-3 3]);
%
% Notes:
%   - Units are sorted by Cohen's d value within each group
%   - EMX units are plotted first, followed by PVALB units
%   - Color coding indicates response type and subtype
%   - Treatment time is marked at 1860/5 timepoint
%   - Figures are saved as both .fig and .tif (300 DPI) formats
%
% See also: IMAGESC, COLORMAP, REDBLUE

%% Resolve Input Args
    % Parse optional parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct');
    addRequired(p, 'figureFolder');
    addParameter(p, 'UnitFilter', 'both', @ischar);
    addParameter(p, 'OutlierFilter', true, @islogical);
    addParameter(p, 'ColorLimits', [-2 2], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'FontSize', 10, @isnumeric);
    parse(p, cellDataStruct, figureFolder, varargin{:});
    opts = p.Results;

    % Define color scheme for response types and subtypes
    colorMap = containers.Map();
    colorMap('Increased_Strong') = [0.8 0 0];        % Deep red
    colorMap('Increased_Moderate') = [1 0.2 0.2];    % Bright red
    colorMap('Increased_Variable') = [1 0.4 0.4];    % Light red
    colorMap('Decreased_Strong') = [0 0 0.8];        % Deep blue
    colorMap('Decreased_Moderate') = [0 0.2 1];      % Bright blue
    colorMap('Decreased_Variable') = [0.4 0.4 1];    % Light blue
    colorMap('Changed_Weak') = [0.5 0 0.5];         % Purple
    colorMap('No_Change_None') = [0.4 0.4 0.4];     % Gray
    
    %% Main Function

    % Process each group separately first
    groupData = struct();
    groupsToProcess = {'Emx', 'Pvalb'}; % Order matters for plotting
    
    % Process each group
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        if ~isfield(cellDataStruct, groupName)
            error('Group %s not found in data structure', groupName);
        end
        
        % Initialize arrays for this group
        groupData.(groupName) = struct();
        groupData.(groupName).PSTHs = [];
        groupData.(groupName).CohensD = [];
        groupData.(groupName).Colors = [];
        groupData.(groupName).Labels = {};
        
        % Process recordings in this group
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
           % In the main processing loop where units are being checked:
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check unit validity
                if ~isValidUnit(unitData, opts.UnitFilter, opts.OutlierFilter)
                    continue;
                end
            
                if isfield(unitData, 'psthZScore') && isfield(unitData, 'responseMetrics')
                    % Only include Strong or Moderate responses
                    if ~isfield(unitData.responseMetrics, 'subtype') || ...
                       (~strcmp(unitData.responseMetrics.subtype, 'Strong') && ...
                        ~strcmp(unitData.responseMetrics.subtype, 'Moderate'))
                        continue;
                    end
            
                    % Get response type and subtype
                    responseType = strrep(unitData.responseType, ' ', '_');
                    subtype = unitData.responseMetrics.subtype;
                    colorKey = sprintf('%s_%s', responseType, subtype);
            
                    % Store data
                    groupData.(groupName).PSTHs = [groupData.(groupName).PSTHs; unitData.psthZScore];
                    groupData.(groupName).CohensD = [groupData.(groupName).CohensD; ...
                        unitData.responseMetrics.stats.cohens_d];
                    groupData.(groupName).Labels = [groupData.(groupName).Labels; unitID];
                    
                    if colorMap.isKey(colorKey)
                        groupData.(groupName).Colors = [groupData.(groupName).Colors; colorMap(colorKey)];
                    else
                        groupData.(groupName).Colors = [groupData.(groupName).Colors; [0.7 0.7 0.7]];
                    end
                end
            end
        
            % Sort each group by Cohen's d
            [~, sortIdx] = sort(groupData.(groupName).CohensD, 'descend');
            groupData.(groupName).PSTHs = groupData.(groupName).PSTHs(sortIdx, :);
            groupData.(groupName).CohensD = groupData.(groupName).CohensD(sortIdx);
            groupData.(groupName).Colors = groupData.(groupName).Colors(sortIdx, :);
            groupData.(groupName).Labels = groupData.(groupName).Labels(sortIdx);
       
        end
    end

    % Create separate figures for Cohen's d and heatmap
    fig1 = figure('Position', [100 100 800 800]);
    fig2 = figure('Position', [100 100 800 800]);
    
    % Sort EMX data by Cohen's d
    [emx_d_sorted, emx_idx] = sort(groupData.Emx.CohensD, 'descend');
    emx_colors_sorted = groupData.Emx.Colors(emx_idx, :);
    emx_psth_sorted = groupData.Emx.PSTHs(emx_idx, :);
    
    % Sort PVALB data by Cohen's d
    [pvalb_d_sorted, pvalb_idx] = sort(groupData.Pvalb.CohensD, 'descend');
    pvalb_colors_sorted = groupData.Pvalb.Colors(pvalb_idx, :);
    pvalb_psth_sorted = groupData.Pvalb.PSTHs(pvalb_idx, :);
    
    %% Plotting

    % Plot Cohen's d (fig1)
    figure(fig1);
    hold on;
    
    % Plot EMX Cohen's d values first
    for i = 1:length(emx_d_sorted)
        barh(i, emx_d_sorted(i), 'FaceColor', emx_colors_sorted(i,:), 'EdgeColor', 'none');
    end
    
    % Add separator
    yline(length(emx_d_sorted) + 0.5, 'k-', 'LineWidth', 2);
    
    % Plot PVALB Cohen's d values second
    for i = 1:length(pvalb_d_sorted)
        barh(i + length(emx_d_sorted), pvalb_d_sorted(i), 'FaceColor', pvalb_colors_sorted(i,:), 'EdgeColor', 'none');
    end
    
    % Format Cohen's d plot
    yticks([length(emx_d_sorted)/2, length(emx_d_sorted) + length(pvalb_d_sorted)/2]);
    yticklabels({'EMX', 'PVALB'});
    xlabel('Cohen''s d', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Effect Size', 'FontSize', opts.FontSize + 2);
    set(gca, 'YDir', 'reverse');
    grid on;
    
     % Plot Z-score heatmap (fig2)
    figure(fig2);
    
    % Calculate gap size (e.g., 2 units worth of space)
    gapSize = 2;
    
    % Create white gap between groups using NaN values
    whiteGap = nan(gapSize, size(emx_psth_sorted, 2));
    combinedPSTHs = [emx_psth_sorted; whiteGap; pvalb_psth_sorted];
    
    % Plot heatmap
    imagesc(combinedPSTHs);
    colormap(redblue(256));
    set(gca, 'Color', 'w');  % Set background color to white (for NaN values)
    
    % Add colorbar without text
    c = colorbar;
    c.Label.String = '';
    c.TickLabels = [];
    
    % Customize appearance
    set(gca, 'XTickLabel', [], 'YTickLabel', [], ...
        'FontSize', opts.FontSize, ...
        'Box', 'off', ...
        'TickDir', 'out');
    
    % Add treatment time marker
    hold on;
    timeInBins = 1800 * (1000/5);  % Convert 1800 seconds to bins
    xline(timeInBins, ':', 'Color', 'k', 'LineWidth', 3);
    hold off;
    
    % Set color limits
    clim(opts.ColorLimits);
    
%% Helper functions 
% Validate Units
function isValid = isValidUnit(unitData, unitFilter, outlierFilter)
    % Check outlier status
    if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        isValid = false;
        return;
    end
    
    % Check unit type
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
       strcmp(unitFilter, 'multi') && isSingleUnit
        isValid = false;
        return;
    end
    
    isValid = true;
end

% Generate color bank for heat-map
function c = redblue(m)
    % Custom red-blue colormap
    if nargin < 1
        m = 256;
    end
    
    bottom = [0 0 1];
    middle = [1 1 1];
    top = [1 0 0];
    
    % Create color segments
    bottom_half = interp1([0 1], [bottom; middle], linspace(0,1,ceil(m/2)));
    top_half = interp1([0 1], [middle; top], linspace(0,1,floor(m/2)));
    
    c = [bottom_half; top_half(2:end,:)];
end 