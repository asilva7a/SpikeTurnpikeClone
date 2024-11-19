function plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, varargin)
%% Example Use:
% Basic usage
% plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, 10);
%
% *Input:
% * CellDataStruct
% * figureFolder
% * boxCar Width
%
% With optional parameters
% plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, 10, ...
%     'TreatmentTime', 1860, ...
%     'UnitFilter', 'single', ...
%     'OutlierFilter', true, ...
%     'PlotType', 'mean+sem', ...
%     'ShowGrid', true, ...
%     'LineWidth', 2, ...
%     'TraceAlpha', 0.3, ...
%     'YLimits', [0 5], ...
%     'FontSize', 12);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Parse optional parameters
    p = inputParser;
    addRequired(p, 'cellDataStruct');
    addRequired(p, 'figureFolder');
    addParameter(p, 'TreatmentTime', 1860, @isnumeric);
    addParameter(p, 'UnitFilter', 'both', @ischar);
    addParameter(p, 'OutlierFilter', true, @islogical);
    addParameter(p, 'PlotType', 'mean+sem', @ischar);
    addParameter(p, 'ShowGrid', true, @islogical);
    addParameter(p, 'LineWidth', 1.5, @isnumeric);
    addParameter(p, 'TraceAlpha', 0.2, @(x) isnumeric(x) && x >= 0 && x <= 1);
    addParameter(p, 'YLimits', [], @(x) isempty(x) || (isnumeric(x) && length(x) == 2));
    addParameter(p, 'FontSize', 10, @isnumeric);
    parse(p, cellDataStruct, figureFolder, varargin{:});
    opts = p.Results;

    % Constants with improved colors
    COLORS = struct(...
        'Increased', [1, 0, 1], ...    % Magenta
        'Decreased', [0, 1, 1], ...    % Cyan
        'No_Change', [0.7, 0.7, 0.7]); % Grey

    % Process each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            
            % Create save directory
            saveDir = fullfile(figureFolder, groupName, recordingName, '0. recordingFigures');
            if ~isfolder(saveDir)
                mkdir(saveDir);
            end
            
            % Collect and organize unit data
            [responseData, timeVector] = collectUnitData(cellDataStruct.(groupName).(recordingName), ...
                                                       opts.UnitFilter, opts.OutlierFilter);
            
            if isempty(timeVector)
                warning('Plot:NoData', 'No valid units found in %s/%s', groupName, recordingName);
                continue;
            end
            
            % Create and save figure
            createAndSaveFigure(responseData, timeVector, opts, ...
                              COLORS, groupName, recordingName, saveDir);
        end
    end
end

function [responseData, timeVector] = collectUnitData(recordingData, unitFilter, outlierFilter)
    % Initialize data structures
    responseData = struct(...
        'Increased', [], ...
        'Decreased', [], ...
        'No_Change', []);
    timeVector = [];
    
    units = fieldnames(recordingData);
    for u = 1:length(units)
        unitData = recordingData.(units{u});
        
        % Check unit validity
        if ~isValidUnit(unitData, unitFilter, outlierFilter)
            continue;
        end
        
        % Process valid unit
        if isfield(unitData, 'psthPercentChange') && isfield(unitData, 'responseType')
            % Get time vector if not set
            if isempty(timeVector) && isfield(unitData, 'binEdges') && isfield(unitData, 'binWidth')
                timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
            end
            
            % Add data to appropriate response type
            responseType = strrep(unitData.responseType, ' ', '');
            if isfield(responseData, responseType)
                responseData.(responseType) = [responseData.(responseType); unitData.psthPercentChange];
            end
        end
    end
end

function createAndSaveFigure(responseData, timeVector, opts, colors, groupName, recordingName, saveDir)
    fig = figure('Position', [100, 100, 1200, 400]);
    t = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    
    title(t, sprintf('%s - %s', groupName, recordingName), ...
          'FontSize', opts.FontSize + 4);
    
    responseTypes = {'Increased', 'Decreased', 'No_Change'};
    for i = 1:length(responseTypes)
        nexttile
        plotResponseType(responseData.(responseTypes{i}), timeVector, ...
                        colors.(responseTypes{i}), responseTypes{i}, opts);
    end
    
    % Save figure
    timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
    filename = sprintf('%s_%s_PercentChange_%s', ...
                      groupName, recordingName, timestamp);
    savefig(fig, fullfile(saveDir, [filename '.fig']));
    saveas(fig, fullfile(saveDir, [filename '.png']));
    close(fig);
end

function plotResponseType(data, timeVector, color, titleStr, opts)
    if isempty(data)
        title(sprintf('%s (No Data)', titleStr));
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
    
    % Use shadedErrorBar for mean±SEM plot
    shadedErrorBar(timeVector, meanData, semData, ...
                  'lineprops', {'Color', color, 'LineWidth', opts.LineWidth}, ...
                  'patchSaturation', 0.2);
    
    % Add treatment line
    xline(opts.TreatmentTime, '--k', 'LineWidth', 1, 'Alpha', 0.5);
    
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
    title(sprintf('%s Units (n=%d)', titleStr, size(data, 1)), ...
          'FontSize', opts.FontSize + 1);
    xlabel('Time (s)', 'FontSize', opts.FontSize);
    ylabel('% Change from Baseline', 'FontSize', opts.FontSize);
    
    set(gca, 'FontSize', opts.FontSize);
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
    
    isValid = true;
end
