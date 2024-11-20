function [figHandles, unitTable] = plotUnitZScoreHeatmapAllUnits(cellDataStruct, paths, varargin)
    % PLOTUNITZSCOREHEATMAP Creates heatmaps of neural unit responses using Z-scores
    %
    % This function creates two visualizations:
    % 1. A Z-score heatmap showing temporal dynamics of all units
    % 2. A Cohen's d plot showing effect sizes for all units
    % Units are sorted by Cohen's d and colored by response type
    
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
    groupsToProcess = {'Emx', 'Pvalb'};
    
    % Initialize group data structure
    groupData = struct();
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        groupData.(groupName) = struct(...
            'PSTHs', [], ...
            'CohensD', [], ...
            'Colors', [], ...
            'Labels', {});
    end

    % Process each group
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        if ~isfield(cellDataStruct, groupName)
            error('Group %s not found in data structure', groupName);
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
        
        % Sort each group's data by Cohen's d
        [~, sortIdx] = sort(groupData.(groupName).CohensD, 'descend');
        groupData.(groupName).PSTHs = groupData.(groupName).PSTHs(sortIdx, :);
        groupData.(groupName).CohensD = groupData.(groupName).CohensD(sortIdx);
        groupData.(groupName).Colors = groupData.(groupName).Colors(sortIdx, :);
        groupData.(groupName).Labels = groupData.(groupName).Labels(sortIdx);
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

    % Combine sorted data from all groups
    combinedPSTHs = [];
    combinedCohensD = [];
    combinedColors = [];
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        combinedPSTHs = [combinedPSTHs; groupData.(groupName).PSTHs];
        combinedCohensD = [combinedCohensD; groupData.(groupName).CohensD];
        combinedColors = [combinedColors; groupData.(groupName).Colors];
    end

    % Create figures
    fig1 = figure('Position', [100 100 800 800]);
    fig2 = figure('Position', [100 100 800 800]);

    % Plot Cohen's d (fig1)
    figure(fig1);
    hold on;
    
    currentIdx = 1;
    for g = 1:length(groupsToProcess)
        groupName = groupsToProcess{g};
        numUnits = length(groupData.(groupName).CohensD);
        
        for i = 1:numUnits
            barh(currentIdx, groupData.(groupName).CohensD(i), ...
                'FaceColor', groupData.(groupName).Colors(i,:), ...
                'EdgeColor', 'none');
            currentIdx = currentIdx + 1;
        end
        
        if g < length(groupsToProcess)
            yline(currentIdx - 0.5, 'k-', 'LineWidth', 2);
        end
    end

    xlabel('Cohen''s d', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Effect Size', 'FontSize', opts.FontSize + 2);
    set(gca, 'YDir', 'reverse');
    grid on;

    % Add legend for Cohen's d plot
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

    % Plot Z-score heatmap (fig2)
    figure(fig2);
    imagesc(combinedPSTHs, opts.ColorLimits);
    colormap(redblue(256));
    c = colorbar;
    c.Label.String = 'Z-Score';

    % Add treatment time line
    hold on;
    xline(1860/5, '--w', 'LineWidth', 1);
    
    % Add group separation lines
    currentIdx = 0;
    for g = 1:length(groupsToProcess)-1
        groupName = groupsToProcess{g};
        currentIdx = currentIdx + length(groupData.(groupName).CohensD);
        yline(currentIdx + 0.5, 'w-', 'LineWidth', 2);
    end
    hold off;

    xlabel('Time (ms)', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked by Cohen''s d)', 'FontSize', opts.FontSize);
    title('Z-Score Changes', 'FontSize', opts.FontSize + 2);
    set(gca, 'YDir', 'reverse');

    % Save figures
    saveDir = fullfile(paths.figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end

    try
        timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
        
        % Save Cohen's d plot
        savefig(fig1, fullfile(saveDir, sprintf('CohensD_AllUnits_%s.fig', timestamp)));
        print(fig1, fullfile(saveDir, sprintf('CohensD_AllUnits_%s.tif', timestamp)), '-dtiff', '-r300');
        
        % Save heatmap
        savefig(fig2, fullfile(saveDir, sprintf('ZScoreHeatmap_AllUnits_%s.fig', timestamp)));
        print(fig2, fullfile(saveDir, sprintf('ZScoreHeatmap_AllUnits_%s.tif', timestamp)), '-dtiff', '-r300');
        
        % Save table
        writetable(unitTable, fullfile(saveDir, sprintf('UnitStats_%s.csv', timestamp)));
        
        close(fig1);
        close(fig2);
    catch ME
        warning('Save:Error', 'Error saving figures: %s', ME.message);
    end

    % Return figure handles
    figHandles = [fig1, fig2];
end

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
