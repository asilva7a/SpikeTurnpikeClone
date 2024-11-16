function plotUnitPercentChangeHeatmap(cellDataStruct, figureFolder, varargin)
    % Parse optional parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct');
    addRequired(p, 'figureFolder');
    addParameter(p, 'UnitFilter', 'both', @ischar);
    addParameter(p, 'OutlierFilter', true, @islogical);
    addParameter(p, 'BoxCarWindow', 10, @isnumeric);
    addParameter(p, 'ColorLimits', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'FontSize', 10, @isnumeric);
    parse(p, cellDataStruct, figureFolder, varargin{:});
    opts = p.Results;

    % Initialize storage for all units
    allPSTHs = [];
    allPercentChanges = [];
    allLabels = {};
    allGroups = {};
    
    % Collect data from all groups and recordings
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
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
                
                if isfield(unitData, 'psthPercentChange') && isfield(unitData, 'responseType')
                    % Smooth the data
                    smoothedPSTH = smoothdata(unitData.psthPercentChange, 'movmean', opts.BoxCarWindow);
                    
                    % Calculate mean percent change (post vs pre)
                    meanChange = mean(smoothedPSTH(unitData.binEdges(1:end-1) > 1860)) - ...
                               mean(smoothedPSTH(unitData.binEdges(1:end-1) <= 1860));
                    
                    % Store data
                    allPSTHs = [allPSTHs; smoothedPSTH];
                    allPercentChanges = [allPercentChanges; meanChange];
                    allLabels{end+1} = sprintf('%s_%s_%s', groupName, recordingName, unitID);
                    allGroups{end+1} = unitData.responseType;
                end
            end
        end
    end
    
    % Sort units by mean percent change
    [sortedChanges, sortIdx] = sort(allPercentChanges, 'descend');
    sortedPSTHs = allPSTHs(sortIdx, :);
    sortedLabels = allLabels(sortIdx);
    sortedGroups = allGroups(sortIdx);
    
    % Create figure
    fig = figure('Position', [100 100 1200 800]);
    t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    % Plot heatmap
    nexttile
    if isempty(opts.ColorLimits)
        imagesc(sortedPSTHs);
    else
        imagesc(sortedPSTHs, opts.ColorLimits);
    end
    colormap(redblue(256));  % Custom colormap: blue-white-red
    colorbar;
    
    % Add labels
    xlabel('Time (s)', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Firing Rate Changes (Ranked)', 'FontSize', opts.FontSize + 2);
    
    % Add treatment line
    hold on;
    xline(find(unitData.binEdges(1:end-1) >= 1860, 1), '--w', 'LineWidth', 2);
    hold off;
    
    % Plot sorted percent changes
    nexttile
    barh(sortedChanges);
    
    % Color bars by response type
    hold on;
    for i = 1:length(sortedGroups)
        switch strrep(sortedGroups{i}, ' ', '')
            case 'Increased'
                color = [1 0 1];  % Magenta
            case 'Decreased'
                color = [0 1 1];  % Cyan
            otherwise
                color = [0.7 0.7 0.7];  % Grey
        end
        barh(i, sortedChanges(i), 'FaceColor', color, 'EdgeColor', 'none');
    end
    hold off;
    
    xlabel('Mean % Change', 'FontSize', opts.FontSize);
    ylabel('Units (Ranked)', 'FontSize', opts.FontSize);
    title('Mean Response Magnitude', 'FontSize', opts.FontSize + 2);
    
    % Add overall title
    title(t, 'Population Response Heatmap', 'FontSize', opts.FontSize + 4);
    
    % Save figure
    saveDir = fullfile(figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('ResponseHeatmap_BoxCar%ds_%s', opts.BoxCarWindow, timestamp);
    savefig(fig, fullfile(saveDir, [filename '.fig']));
    saveas(fig, fullfile(saveDir, [filename '.png']));
    close(fig);
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
