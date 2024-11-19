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

    % Define color scheme for response types
    colorMap = containers.Map();
    colorMap('Increased') = [1 0 0];        % Red for enhanced
    colorMap('Decreased') = [0 0 1];        % Blue for diminished
    colorMap('No_Change') = [0.7 0.7 0.7];  % Gray for no change

    % Initialize storage for all units
    allPSTHs = [];
    allCohensD = [];
    allColors = [];
    allLabels = {};
    allGroups = {};
    
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

    % Process each group
    groupsToProcess = {'Emx', 'Pvalb'};
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
                    % Get response type
                    responseType = strrep(unitData.responseType, ' ', '');
                    
                    % Store data
                    allPSTHs = [allPSTHs; unitData.psthZScore];
                    allCohensD = [allCohensD; unitData.responseMetrics.stats.cohens_d];
                    allLabels = [allLabels; unitID];
                    allGroups = [allGroups; groupName];
                    
                    % Assign color based on response type
                    if colorMap.isKey(responseType)
                        allColors = [allColors; colorMap(responseType)];
                    else
                        allColors = [allColors; [0.7 0.7 0.7]];
                    end
                    
                    % Store data for table
                    tableData.UnitID{end+1} = unitID;
                    tableData.Group{end+1} = groupName;
                    tableData.CohensD(end+1) = unitData.responseMetrics.stats.cohens_d;
                    tableData.CI_Pre_Lower(end+1) = unitData.responseMetrics.stats.ci_pre(1);
                    tableData.CI_Pre_Upper(end+1) = unitData.responseMetrics.stats.ci_pre(2);
                    tableData.CI_Post_Lower(end+1) = unitData.responseMetrics.stats.ci_post(1);
                    tableData.CI_Post_Upper(end+1) = unitData.responseMetrics.stats.ci_post(2);
                    tableData.ResponseType{end+1} = responseType;
                end
            end
        end
    end

    % Create table
    unitTable = table(tableData.UnitID', tableData.Group', tableData.CohensD', ...
                     tableData.CI_Pre_Lower', tableData.CI_Pre_Upper', ...
                     tableData.CI_Post_Lower', tableData.CI_Post_Upper', ...
                     tableData.ResponseType', ...
                     'VariableNames', {'UnitID', 'Group', 'CohensD', ...
                                     'CI_Pre_Lower', 'CI_Pre_Upper', ...
                                     'CI_Post_Lower', 'CI_Post_Upper', ...
                                     'ResponseType'});

    % Sort all data by Cohen's d
    [sortedD, sortIdx] = sort(allCohensD, 'descend');
    sortedPSTHs = allPSTHs(sortIdx, :);
    sortedColors = allColors(sortIdx, :);
    sortedLabels = allLabels(sortIdx);
    sortedGroups = allGroups(sortIdx);

    % Create figures
    fig1 = figure('Position', [100 100 800 800]);
    fig2 = figure('Position', [100 100 800 800]);

    % Plot Cohen's d (fig1)
    figure(fig1);
    hold on;
    for i = 1:length(sortedD)
        barh(i, sortedD(i), 'FaceColor', sortedColors(i,:), 'EdgeColor', 'none');
    end
    xlabel('Cohen''s d', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Effect Size', 'FontSize', opts.FontSize + 2);
    set(gca, 'YDir', 'reverse');
    grid on;

    % Add legend for Cohen's d plot
    h1 = plot(nan, nan, 'Color', colorMap('Increased'), 'LineWidth', 2);
    h2 = plot(nan, nan, 'Color', colorMap('Decreased'), 'LineWidth', 2);
    h3 = plot(nan, nan, 'Color', colorMap('No_Change'), 'LineWidth', 2);
    legend([h1 h2 h3], {'Enhanced', 'Diminished', 'No Change'}, ...
        'Location', 'southeast', ...
        'FontSize', opts.FontSize, ...
        'Box', 'off');

    % Plot Z-score heatmap (fig2)
    figure(fig2);
    imagesc(sortedPSTHs, opts.ColorLimits);
    colormap(redblue(256));
    c = colorbar;
    c.Label.String = 'Z-Score';

    % Add treatment time line
    hold on;
    xline(1860/5, '--w', 'LineWidth', 1);
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
