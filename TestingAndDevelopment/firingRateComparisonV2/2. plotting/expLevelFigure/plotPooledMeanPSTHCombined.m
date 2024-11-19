function plotPooledMeanPSTHCombined(cellDataStruct, paths, params, varargin)

    % Parse optional parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct');
    addRequired(p, 'paths');
    addRequired(p, 'params');
    
    % Analysis parameters
    addParameter(p, 'UnitFilter', 'both', @ischar);
    addParameter(p, 'OutlierFilter', true, @islogical);
    
    % Plotting parameters
    addParameter(p, 'PlotType', 'mean+sem', @ischar);
    addParameter(p, 'ShowGrid', true, @islogical);
    addParameter(p, 'LineWidth', 1.5, @isnumeric);
    addParameter(p, 'TraceAlpha', 0.2, @(x) isnumeric(x) && x >= 0 && x <= 1);
    addParameter(p, 'YLimits', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'FontSize', 10, @isnumeric);
    
    parse(p, cellDataStruct, paths, params, varargin{:});
    opts = p.Results;

    
    % Constants with improved colors
    COLORS = struct(...
        'Increased', [1, 0, 0], ...    % Magenta
        'Decreased', [0, 0, 1], ...    % Cyan
        'No_Change', [0.7, 0.7, 0.7]); % Grey
    
    % Initialize data collection
    responseData = struct(...
        'Increased', [], ...
        'Decreased', [], ...
        'No_Change', [], ...
        'timeVector', []);
    
    % Create save directory
    saveDir = fullfile(paths.figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    % Process experimental groups
    experimentalGroups = {'Emx', 'Pvalb'};
    for g = 1:length(experimentalGroups)
        groupName = experimentalGroups{g};
        if ~isfield(cellDataStruct, groupName)
            warning('Plot:NoGroup', 'Group %s not found in data', groupName);
            continue;
        end
        
        % Process recordings
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            responseData = processRecording(cellDataStruct.(groupName).(recordingName), ...
                responseData, opts.UnitFilter, opts.OutlierFilter);

        end
    end
    
    % Create and save figure if data exists
    if ~isempty(responseData.timeVector)
        createAndSaveFigure(responseData, params.treatmentTime, opts, COLORS, saveDir);
    else
        warning('Plot:NoData', 'No valid units found for plotting');
    end
end

function responseData = processRecording(recordingData, responseData, unitFilter, outlierFilter)
    units = fieldnames(recordingData);
    for u = 1:length(units)
        unitData = recordingData.(units{u});
        
        % Check unit validity
        if ~isValidUnit(unitData, unitFilter, outlierFilter)
            continue;
        end
        
        % Process valid unit
        if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
            % Get time vector if not set
            if isempty(responseData.timeVector) && isfield(unitData, 'binEdges')
                responseData.timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
            end
            
            % Add data to appropriate response type
            responseType = strrep(unitData.responseType, ' ', '');
            if isfield(responseData, responseType)
                responseData.(responseType) = [responseData.(responseType); unitData.psthSmoothed];
            end
        end
    end
end

function createAndSaveFigure(responseData, treatmentTime, opts, colors, saveDir)
    fig = figure('Position', [100, 100, 1200, 400]);
    t = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    title(t, sprintf('Pooled Emx and Pvalb Response Types'), ...
        'FontSize', opts.FontSize + 4, 'Interpreter', 'none');
    
    responseTypes = {'Increased', 'Decreased', 'No_Change'};
    for i = 1:length(responseTypes)
        nexttile
        plotResponseType(responseData.(responseTypes{i}), responseData.timeVector, ...
            colors.(responseTypes{i}), responseTypes{i}, treatmentTime, opts);
    end
    
    % Add common xlabel and ylabel to the tiledlayout
    xlabel(t, 'Time (s)', 'FontSize', opts.FontSize);
    ylabel(t, 'Firing Rate (Hz)', 'FontSize', opts.FontSize);
    
    % Save figure
    try
        timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('Pooled_Emx_Pvalb_%s_%s', opts.PlotType, timestamp);
        savefig(fig, fullfile(saveDir, [fileName '.fig']));
        saveas(fig, fullfile(saveDir, [fileName '.png']));
        close(fig);
    catch ME
        warning('Save:Error', 'Error saving figure: %s', ME.message);
    end
end

function plotResponseType(data, timeVector, color, titleStr, treatmentTime, opts)
    if isempty(data)
        title(sprintf('%s (No Data)', titleStr), 'Interpreter', 'none');
        return;
    end
    
    hold on;
    
    % Plot individual traces if enabled
    if strcmp(opts.PlotType, 'mean+individual')
        for i = 1:size(data, 1)
            plot(timeVector, data(i,:), 'Color', [color opts.TraceAlpha], ...
                'LineWidth', opts.LineWidth/3);
        end
    end
    
    % Calculate mean and SEM
    meanData = mean(data, 1, 'omitnan');
    semData = std(data, 0, 1, 'omitnan') / sqrt(size(data, 1));
    
    % Plot mean ± SEM using shadedErrorBar
    shadedErrorBar(timeVector, meanData, semData, ...
        'lineProps', {'Color', color, 'LineWidth', opts.LineWidth}, ...
        'patchSaturation', 0.2);
    
    % Add treatment line
    xline(treatmentTime, '--k', 'LineWidth', 1, 'Alpha', 0.5);
    
    % Set axis properties
    if ~isempty(opts.YLimits)
        ylim(opts.YLimits);
    end
    xlim([0 max(timeVector)]);
    
    if opts.ShowGrid
        grid on;
        set(gca, 'Layer', 'top', 'GridAlpha', 0.15);
    end
    
    % Add labels
    title(sprintf('%s Units (n=%d)', strrep(titleStr, '_', ' '), size(data, 1)), ...
        'FontSize', opts.FontSize + 1, 'Interpreter', 'none');
    
    set(gca, 'FontSize', opts.FontSize, 'Box', 'off', 'TickDir', 'out');
    hold off;
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
    
    % Check required fields
    isValid = isfield(unitData, 'psthSmoothed') && ...
              isfield(unitData, 'responseType') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
end

