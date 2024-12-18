function [unitTable] = plotUnitZScoreHeatmapAllUnits(cellDataStruct, paths, varargin)
    % Parse optional parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct');
    addRequired(p, 'paths');
    addParameter(p, 'UnitFilter', 'both', @ischar);
    addParameter(p, 'OutlierFilter', true, @islogical);
    addParameter(p, 'ColorLimits', [-2 2], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'FontSize', 10, @isnumeric);
    parse(p, cellDataStruct, paths, varargin{:});
    opts = p.Results;

    % Define color scheme
    colorMap = containers.Map();
    colorMap('Increased_Strong') = [0.8 0 0];        % Deep red
    colorMap('Increased_Moderate') = [1 0.2 0.2];    % Bright red
    colorMap('Increased_Variable') = [1 0.4 0.4];    % Light red
    colorMap('Decreased_Strong') = [0 0 0.8];        % Deep blue
    colorMap('Decreased_Moderate') = [0 0.2 1];      % Bright blue
    colorMap('Decreased_Variable') = [0.4 0.4 1];    % Light blue
    colorMap('Changed_Weak') = [0.5 0 0.5];         % Purple
    colorMap('No_Change_None') = [0.4 0.4 0.4];     % Gray

    % Initialize table data
    tableData = struct();
    tableData.UnitID = {};
    tableData.Group = {};
    tableData.CohensD = [];
    tableData.CI_Pre_Lower = [];
    tableData.CI_Pre_Upper = [];
    tableData.CI_Post_Lower = [];
    tableData.CI_Post_Upper = [];
    tableData.ResponseType = {};
    tableData.Subtype = {};

    % Define groups to process
    groupsToProcess = {'Emx', 'Pvalb', 'Control'};
    
    % Initialize group data structure
    groupData = struct();
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        groupData(1).(groupName).PSTHs = [];
        groupData(1).(groupName).CohensD = [];
        groupData(1).(groupName).Colors = [];
        groupData(1).(groupName).Labels = {};
    end

    % Process each group
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        % Process recordings in this group
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check unit validity
                if ~isValidUnit(unitData, opts.UnitFilter, opts.OutlierFilter)
                    continue;
                end
                
                if isfield(unitData, 'psthZScore') && isfield(unitData, 'responseMetrics')
                    % Get response type and subtype
                    responseType = strrep(unitData.responseType, ' ', '_');
                    subtype = unitData.responseMetrics.subtype;
                    colorKey = sprintf('%s_%s', responseType, subtype);
                    
                    % Store data
                    groupData.(groupName).PSTHs = [groupData.(groupName).PSTHs; unitData.psthZScore];
                    groupData.(groupName).CohensD = [groupData.(groupName).CohensD; unitData.responseMetrics.stats.cohens_d];
                    groupData.(groupName).Labels = [groupData.(groupName).Labels; unitID];
                    
                    if colorMap.isKey(colorKey)
                        groupData.(groupName).Colors = [groupData.(groupName).Colors; colorMap(colorKey)];
                    else
                        groupData.(groupName).Colors = [groupData.(groupName).Colors; [0.7 0.7 0.7]];
                    end
                    
                    % Store data for table
                    tableData.UnitID{end+1} = unitID;
                    tableData.Group{end+1} = groupName;
                    tableData.Subtype{end+1} = subtype;
                    tableData.CohensD(end+1) = unitData.responseMetrics.stats.cohens_d;
                    tableData.CI_Pre_Lower(end+1) = unitData.responseMetrics.stats.ci_pre(1);
                    tableData.CI_Pre_Upper(end+1) = unitData.responseMetrics.stats.ci_pre(2);
                    tableData.CI_Post_Lower(end+1) = unitData.responseMetrics.stats.ci_post(1);
                    tableData.CI_Post_Upper(end+1) = unitData.responseMetrics.stats.ci_post(2);
                    tableData.ResponseType{end+1} = responseType;
                end
            end
        end
        
        % Sort data after collecting all units for this group
        if ~isempty(groupData.(groupName).CohensD)
            [~, sortIdx] = sort(groupData.(groupName).CohensD, 'descend');
            groupData.(groupName).PSTHs = groupData.(groupName).PSTHs(sortIdx, :);
            groupData.(groupName).CohensD = groupData.(groupName).CohensD(sortIdx);
            groupData.(groupName).Colors = groupData.(groupName).Colors(sortIdx, :);
            groupData.(groupName).Labels = groupData.(groupName).Labels(sortIdx);
            groupData.(groupName).UnitRanks = (1:length(sortIdx))';
        end
    end

    % Create table
    unitTable = table(tableData.UnitID', tableData.Group', tableData.CohensD', ...
                     tableData.CI_Pre_Lower', tableData.CI_Pre_Upper', ...
                     tableData.CI_Post_Lower', tableData.CI_Post_Upper', ...
                     tableData.ResponseType', tableData.Subtype', ...
                     'VariableNames', {'UnitID', 'Group', 'CohensD', ...
                                     'CI_Pre_Lower', 'CI_Pre_Upper', ...
                                     'CI_Post_Lower', 'CI_Post_Upper', ...
                                     'ResponseType', 'Subtype'});

    % Create figures
    fig1 = figure('Position', [100 100 800 800]);
    fig2 = figure('Position', [100 100 800 800]);

    % Main plotting section for Cohen's d (fig1)
    figure(fig1);
    hold on;
    currentIdx = 1;
    
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        if ~isfield(groupData, groupName) || isempty(groupData.(groupName).CohensD)
            continue;
        end
        
        % Get all units for this group
        groupMask = strcmp(tableData.Group, groupName);
        groupUnits = tableData.UnitID(groupMask);
        groupCohenD = tableData.CohensD(groupMask);
        groupResponses = tableData.ResponseType(groupMask);
        
        % Sort within group
        [sortedCohenD, sortIdx] = sort(groupCohenD, 'descend');
        sortedUnits = groupUnits(sortIdx);
        sortedResponses = groupResponses(sortIdx);
        
        % Plot bars in sorted order
        noChangeIndices = [];
        
        for i = 1:length(sortedUnits)
        % Get color based on response type
        responseType = sortedResponses{i};
        
        % Match color assignment to legend
        switch responseType
            case 'Increased'
                if sortedCohenD(i) > 1
                    barColor = colorMap('Increased_Strong');
                elseif sortedCohenD(i) > 0.5
                    barColor = colorMap('Increased_Moderate');
                else
                    barColor = colorMap('Increased_Variable');
                end
            case 'Decreased'
                if abs(sortedCohenD(i)) > 1
                    barColor = colorMap('Decreased_Strong');
                elseif abs(sortedCohenD(i)) > 0.5
                    barColor = colorMap('Decreased_Moderate');
                else
                    barColor = colorMap('Decreased_Variable');
                end
            case 'Changed'
                barColor = colorMap('Changed_Weak');
            case 'No_Change'
                barColor = colorMap('No_Change_None');
            otherwise
                barColor = [0.7 0.7 0.7];
                fprintf('Warning: Unknown response type: %s\n', responseType);
        end
        
        % Plot bar
        barh(currentIdx, sortedCohenD(i), 'FaceColor', barColor, 'EdgeColor', 'none');
        
        % Track No Change units
        if strcmp(responseType, 'No_Change')
            noChangeIndices = [noChangeIndices; currentIdx];
            fprintf('No Change Unit Found - Group: %s, UnitID: %s, Index: %d, Cohen''s d: %.3f\n', ...
                groupName, sortedUnits{i}, currentIdx, sortedCohenD(i));
        end
            currentIdx = currentIdx + 1;
        end
        
        % Add lines for No Change sequences
        if ~isempty(noChangeIndices)
            % Find consecutive sequences
            breaks = find(diff(noChangeIndices) > 1);
            startIdx = [noChangeIndices(1); noChangeIndices(breaks + 1)];
            endIdx = [noChangeIndices(breaks); noChangeIndices(end)];
            
            % Plot lines for each sequence
            for k = 1:length(startIdx)
                % Draw line above first unit in sequence
                yline(startIdx(k) - 0.5, 'k--', 'LineWidth', 1);
                % Draw line below last unit in sequence
                yline(endIdx(k) + 0.5, 'k--', 'LineWidth', 1);
                fprintf('No Change Sequence %d: Units %d to %d\n', k, startIdx(k), endIdx(k));
            end
        end
        
        % Add group separator
        if g < length(groupsToProcess)
            yline(currentIdx - 0.5, 'k-', 'LineWidth', 4);
        end
    end

    
    % Finalize plot
    xlabel('Cohen''s d', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Effect Size', 'FontSize', opts.FontSize + 2);
    set(gca, 'YDir', 'reverse');
    grid on;
    
    % Add legend
    h1 = plot(nan, nan, 'Color', colorMap('Increased_Strong'), 'LineWidth', 2);
    h2 = plot(nan, nan, 'Color', colorMap('Increased_Moderate'), 'LineWidth', 2);
    h3 = plot(nan, nan, 'Color', colorMap('Increased_Variable'), 'LineWidth', 2);
    h4 = plot(nan, nan, 'Color', colorMap('Decreased_Strong'), 'LineWidth', 2);
    h5 = plot(nan, nan, 'Color', colorMap('Decreased_Moderate'), 'LineWidth', 2);
    h6 = plot(nan, nan, 'Color', colorMap('Decreased_Variable'), 'LineWidth', 2);
    h7 = plot(nan, nan, 'Color', colorMap('Changed_Weak'), 'LineWidth', 2);
    h8 = plot(nan, nan, 'Color', colorMap('No_Change_None'), 'LineWidth', 2);
    
    legend([h1 h2 h3 h4 h5 h6 h7 h8], ...
        {'Enhanced (Strong)', 'Enhanced (Moderate)', 'Enhanced (Variable)', ...
         'Diminished (Strong)', 'Diminished (Moderate)', 'Diminished (Variable)', ...
         'Changed (Weak)', 'No Change'}, ...
        'Location', 'eastoutside', ...
        'FontSize', opts.FontSize, ...
        'Box', 'off');
    
    % % Print final debugging summary
    % fprintf('\nFinal Summary:\n');
    % groupNames = fieldnames(debugLog.groupStats);
    % for g = 1:length(groupNames)
    %     gName = groupNames{g};
    %     stats = debugLog.groupStats.(gName);
    %     fprintf('\n%s Group:\n', gName);
    %     fprintf('Total units: %d\n', stats.totalUnits);
    %     fprintf('Cohen''s d range: %.3f to %.3f\n', stats.cohenDRange(1), stats.cohenDRange(2));
    %     fprintf('No Change units: %d\n', length(stats.noChangeUnits));
    % end

    % Plot Z-score heatmap (fig2)
    figure(fig2);
    t = tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Z-Score Changes', 'FontSize', opts.FontSize + 2);
    
    % Plot each group in its own subplot
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        if ~isfield(groupData, groupName) || isempty(groupData.(groupName).PSTHs)
            continue;
        end
        
        ax = nexttile;
        h = imagesc(groupData.(groupName).PSTHs, opts.ColorLimits);
        colormap(redblue(256));

        % Add tooltips
        dcm = datacursormode(gcf);
        set(dcm, 'Enable', 'on');
        set(dcm, 'UpdateFcn', @(obj,event_obj) customDataTipFunction(obj,event_obj,groupData.(groupName)));

        % Add treatment time line
        hold on;
        xline(1860, '--k', 'LineWidth', 1);
        hold off;
        
        % Add labels
        ylabel(sprintf('%s', groupName), 'FontSize', opts.FontSize);
        
        if g == length(groupsToProcess)
            xlabel('Time (ms)', 'FontSize', opts.FontSize);
        else
            set(gca, 'XTickLabel', []);
        end
        
        set(gca, 'YTick', [], 'YDir', 'reverse');
        numUnits = size(groupData.(groupName).PSTHs, 1);
        ylim([0.5 numUnits+0.5]);
    end
    
    % Add common colorbar
    cb = colorbar;
    cb.Layout.Tile = 'east';
    cb.Label.String = 'Z-Score';

   % Save figures
    saveDir = fullfile(paths.figureFolder, '0. expFigures');
    
    % Create directory if it doesn't exist
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    
    try
        timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        
        % Save Cohen's d plot (fig only)
        savefig(fig1, fullfile(saveDir, sprintf('CohensD_AllUnits_%s.fig', timestamp)));
        
        % Save heatmap (fig only)
        savefig(fig2, fullfile(saveDir, sprintf('ZScoreHeatmap_AllUnits_%s.fig', timestamp)));
        
        % Save table
        writetable(unitTable, fullfile(saveDir, sprintf('UnitStats_%s.csv', timestamp)));
        
        % Close figures
        close(fig1);
        close(fig2);
    catch ME
        warning('Save:Error', 'Error saving files: %s', ME.message);
    end
end

%% Helper Functions

% Custom Tool Tip for units in heat map (doesn't work)
function txt = customDataTipFunction(~, event_obj, groupData)
    pos = event_obj.Position;
    txt = {sprintf('Unit: %s', groupData.Labels{pos(1)}), ...
           sprintf('Rank: %d', groupData.UnitRanks(pos(1))), ...
           sprintf('Z-Score: %.2f', event_obj.Target.CData(pos(1), pos(2)))};
end

% Validate Existing Units Pass Filter Checks
function isValid = isValidUnit(unitData, unitFilter, outlierFilter)
    if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
        isValid = false;
        return;
    end
    
    isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
    if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
       strcmp(unitFilter, 'multi') && isSingleUnit
        isValid = false;
        return;
    end
    
    isValid = true;
end

function c = redblue(m)
% Credit to Adam Auton (2009.10.09) for color map

    % If no input, use current figure's colormap size
    if nargin < 1
        m = size(get(gcf,'colormap'),1);
    end
    
    if (mod(m,2) == 0)
        % Even number of points
        m1 = m*0.5;
        r = (0:m1-1)'/max(m1-1,1);
        g = r;
        r = [r; ones(m1,1)];
        g = [g; flipud(g)];
        b = flipud(r);
    else
        % Odd number of points
        m1 = floor(m*0.5);
        r = (0:m1-1)'/max(m1,1);
        g = r;
        r = [r; ones(m1+1,1)];
        g = [g; 1; flipud(g)];
        b = flipud(r);
    end
    
    c = [r g b];
end
