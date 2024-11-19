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
        'Increased', [1, 0, 0], ...    % Red
        'Decreased', [0, 0, 1], ...    % Blue
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
    fig = figure('Position', [100, 100, 800, 400]);
    t = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    title(t, sprintf('Pooled Response Types'), ...
        'FontSize', opts.FontSize + 4, 'Interpreter', 'none');
    
    % First panel: Experimental (Increased and Decreased)
    nexttile
    [h1, h2] = plotExperimentalPanel(responseData, responseData.timeVector, colors, treatmentTime, opts);
    
    % Second panel: No Change
    nexttile
    h3 = plotResponseType(responseData.No_Change, responseData.timeVector, ...
        colors.No_Change, 'No Change', treatmentTime, opts);
    
    % Add common xlabel and ylabel to the tiledlayout
    xlabel(t, 'Time (s)', 'FontSize', opts.FontSize);
    ylabel(t, 'Firing Rate (Hz)', 'FontSize', opts.FontSize);
    
    % Create legend for both panels
    leg = legend([h1.mainLine, h2.mainLine, h3.mainLine], ...
        {'Enhanced', 'Diminished', 'No Change'}, ...
        'Orientation', 'horizontal');
    leg.Layout.Tile = 'south'; % Place legend below both panels
    
    % Save figure
    try
        timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('Pooled_Responses_%s_%s', opts.PlotType, timestamp);
        savefig(fig, fullfile(saveDir, [fileName '.fig']));
        saveas(fig, fullfile(saveDir, [fileName '.png']));
        close(fig);
    catch ME
        warning('Save:Error', 'Error saving figure: %s', ME.message);
    end
end

function [h1, h2] = plotExperimentalPanel(responseData, timeVector, colors, treatmentTime, opts)
    hold on;
    
    % Initialize handles
    h1 = [];
    h2 = [];
    
    % Plot individual traces if enabled
    if strcmp(opts.PlotType, 'mean+individual')
        % Plot Increased individual traces
        if ~isempty(responseData.Increased)
            for i = 1:size(responseData.Increased, 1)
                plot(timeVector, responseData.Increased(i,:), ...
                    'Color', [colors.Increased 0.05], ...
                    'LineWidth', opts.LineWidth/3);
            end
        end
        
        % Plot Decreased individual traces
        if ~isempty(responseData.Decreased)
            for i = 1:size(responseData.Decreased, 1)
                plot(timeVector, responseData.Decreased(i,:), ...
                    'Color', [colors.Decreased 0.05], ...
                    'LineWidth', opts.LineWidth/3);
            end
        end
    end
    
    % Plot Increased units
    if ~isempty(responseData.Increased)
        meanInc = mean(responseData.Increased, 1, 'omitnan');
        semInc = std(responseData.Increased, 0, 1, 'omitnan') / sqrt(size(responseData.Increased, 1));
        h1 = shadedErrorBar(timeVector, meanInc, semInc, ...
            'lineProps', {'Color', colors.Increased, 'LineWidth', opts.LineWidth}, ...
            'patchSaturation', 0.2);
    end
    
    % Plot Decreased units
    if ~isempty(responseData.Decreased)
        meanDec = mean(responseData.Decreased, 1, 'omitnan');
        semDec = std(responseData.Decreased, 0, 1, 'omitnan') / sqrt(size(responseData.Decreased, 1));
        h2 = shadedErrorBar(timeVector, meanDec, semDec, ...
            'lineProps', {'Color', colors.Decreased, 'LineWidth', opts.LineWidth}, ...
            'patchSaturation', 0.2);
    end
    
    % Add treatment line
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 2, 'Alpha', 0.5);
    
    % Set axis properties
    if ~isempty(opts.YLimits)
        ylim(opts.YLimits);
    end
    xlim([0 max(timeVector)]);
    
    % Make plot square
    axis square
    
    if opts.ShowGrid
        grid on;
        set(gca, 'Layer', 'top', 'GridAlpha', 0.15);
    end
    
    % Add labels
    title(sprintf('Modulated Units\n(Enh: n=%d, Dim: n=%d)', ...
        size(responseData.Increased,1), size(responseData.Decreased,1)), ...
        'FontSize', opts.FontSize + 1, 'Interpreter', 'none');
    
    set(gca, 'FontSize', opts.FontSize, 'Box', 'off', 'TickDir', 'out');
    hold off;
end


function h = plotResponseType(data, timeVector, color, titleStr, treatmentTime, opts)
    if isempty(data)
        title(sprintf('%s (No Data)', titleStr), 'Interpreter', 'none');
        h = [];
        return;
    end
    
    hold on;
    
    % Plot individual traces if enabled
    if strcmp(opts.PlotType, 'mean+individual')
        for i = 1:size(data, 1)
            plot(timeVector, data(i,:), 'Color', [color 0.05], ...  % Much more transparent
                'LineWidth', opts.LineWidth/3);
        end
    end
    
    % Calculate mean and SEM
    meanData = mean(data, 1, 'omitnan');
    semData = std(data, 0, 1, 'omitnan') / sqrt(size(data, 1));
    
    % Plot mean ± SEM using shadedErrorBar
    h = shadedErrorBar(timeVector, meanData, semData, ...
        'lineProps', {'Color', color, 'LineWidth', opts.LineWidth}, ...
        'patchSaturation', 0.2);
    
    % Add treatment line
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 2, 'Alpha', 0.5);
    
    % Set axis properties
    if ~isempty(opts.YLimits)
        ylim(opts.YLimits);
    end
    xlim([0 max(timeVector)]);
    
    % Make plot square
    axis square
    
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
