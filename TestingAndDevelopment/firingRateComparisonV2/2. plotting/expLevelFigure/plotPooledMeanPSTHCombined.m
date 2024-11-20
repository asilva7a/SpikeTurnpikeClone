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
        'Increased', [1, 0, 0], ... % Red
        'Decreased', [0, 0, 1], ... % Blue
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
        if isfield(unitData, 'psthSmoothed') && ...
           isfield(unitData, 'responseType') && ...
           isfield(unitData, 'responseMetrics') && ...
           isfield(unitData.responseMetrics, 'subtype')
            
            % Get time vector if not set
            if isempty(responseData.timeVector) && isfield(unitData, 'binEdges')
                responseData.timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
            end

            % Only include strong or moderate responses
            if strcmp(unitData.responseMetrics.subtype, 'Strong') || ...
               strcmp(unitData.responseMetrics.subtype, 'Moderate')
                % Add data to appropriate response type
                responseType = strrep(unitData.responseType, ' ', '');
                if isfield(responseData, responseType)
                    responseData.(responseType) = [responseData.(responseType); unitData.psthSmoothed];
                end
            end
        end
    end
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
              isfield(unitData, 'responseMetrics') && ...
              isfield(unitData.responseMetrics, 'subtype') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
end

function createAndSaveFigure(responseData, treatmentTime, opts, colors, saveDir)
    fig = figure('Position', [100, 100, 800, 600]);
    hold on;

    % Add treatment line first (behind everything)
    xline(treatmentTime, ':', 'Color', [0, 0, 0], 'LineWidth', 2);

    % Plot mean traces
    if ~isempty(responseData.Increased)
        meanInc = mean(responseData.Increased, 1, 'omitnan');
        semInc = std(responseData.Increased, 0, 1, 'omitnan') / sqrt(size(responseData.Increased, 1));
        h1 = shadedErrorBar(responseData.timeVector, meanInc, semInc, ...
            'lineProps', {'Color', colors.Increased, 'LineWidth', opts.LineWidth}, ...
            'patchSaturation', 0.2);
    end

    if ~isempty(responseData.Decreased)
        meanDec = mean(responseData.Decreased, 1, 'omitnan');
        semDec = std(responseData.Decreased, 0, 1, 'omitnan') / sqrt(size(responseData.Decreased, 1));
        h2 = shadedErrorBar(responseData.timeVector, meanDec, semDec, ...
            'lineProps', {'Color', colors.Decreased, 'LineWidth', opts.LineWidth}, ...
            'patchSaturation', 0.2);
    end

    % Formatting
    if ~isempty(opts.YLimits)
        ylim(opts.YLimits);
    end
    xlim([0 max(responseData.timeVector)]);
    axis square;
    
    % Remove axis labels and tick labels
    set(gca, 'XTickLabel', [], 'YTickLabel', [], ...
        'FontSize', opts.FontSize, 'Box', 'off', 'TickDir', 'out');
    
    hold off;

    % Save main figure
    try
        timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('Pooled_Responses_%s_%s', opts.PlotType, timestamp);
        savefig(fig, fullfile(saveDir, [fileName '.fig']));
        print(fig, fullfile(saveDir, [fileName '.tif']), '-dtiff', '-r300');

        % Create and save legend separately
        if exist('h1', 'var') && exist('h2', 'var')
            legFig = figure('Position', [100, 100, 400, 100]);
            plot([0 1], [0 0], 'Color', colors.Increased, 'LineWidth', opts.LineWidth);
            hold on;
            plot([0 1], [1 1], 'Color', colors.Decreased, 'LineWidth', opts.LineWidth);
            legend({'', ''}, 'Location', 'horizontal', 'Box', 'off');
            set(gca, 'Visible', 'off');
            
            % Save legend
            legFileName = sprintf('Legend_%s', timestamp);
            savefig(legFig, fullfile(saveDir, [legFileName '.fig']));
            print(legFig, fullfile(saveDir, [legFileName '.tif']), '-dtiff', '-r300');
            close(legFig);
        end
        
        close(fig);
    catch ME
        warning('Save:Error', 'Error saving figure: %s', ME.message);
    end
end