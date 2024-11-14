function plotTimeLockedMeanPSTHCombined(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter, outlierFilter)
    % Set defaults
    if nargin < 6, outlierFilter = true; end
    if nargin < 5, unitFilter = 'both'; end
    if nargin < 4, plotType = 'mean+sem'; end
    if nargin < 3, treatmentTime = 1860; end
    
    % Constants
    COLORS = struct(...
        'Increased', [1, 0, 0, 0.3], ...    % Red
        'Decreased', [0, 0, 1, 0.3], ...    % Blue
        'NoChange', [0.5, 0.5, 0.5, 0.3]);  % Grey
    
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
                                                       unitFilter, outlierFilter);
            
            if isempty(timeVector)
                warning('Plot:NoData', 'No valid units found in %s/%s', groupName, recordingName);
                continue;
            end
            
            % Create and save figure
            createAndSaveFigure(responseData, timeVector, treatmentTime, plotType, ...
                              COLORS, groupName, recordingName, unitFilter, saveDir);
        end
    end
end

function [responseData, timeVector] = collectUnitData(recordingData, unitFilter, outlierFilter)
    % Initialize data structures
    responseData = struct(...
        'Increased', [], ...
        'Decreased', [], ...
        'NoChange', []);
    timeVector = [];
    
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
            if isempty(timeVector) && isfield(unitData, 'binEdges') && isfield(unitData, 'binWidth')
                timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
            end
            
            % Add data to appropriate response type
            responseType = strrep(unitData.responseType, ' ', '');
            if isfield(responseData, responseType)
                responseData.(responseType) = [responseData.(responseType); unitData.psthSmoothed];
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
    
    isValid = true;
end

function createAndSaveFigure(responseData, timeVector, treatmentTime, plotType, colors, groupName, recordingName, unitFilter, saveDir)
    fig = figure('Position', [100, 100, 1600, 500]);
    sgtitle(sprintf('%s - %s - %s (%s units)', groupName, recordingName, plotType, unitFilter));
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    for i = 1:length(responseTypes)
        subplot(1, 3, i);
        plotResponseType(responseData.(responseTypes{i}), timeVector, ...
                        colors.(responseTypes{i}), responseTypes{i}, ...
                        treatmentTime, plotType);
    end
    
    % Save figure
    try
        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('%s_%s_%s_recordingSmoothedPSTH_%s.fig', ...
                         groupName, recordingName, plotType, timeStamp);
        savefig(fig, fullfile(saveDir, fileName));
        close(fig);
    catch ME
        warning('Save:Error', 'Error saving figure: %s', ME.message);
    end
end

function plotResponseType(data, timeVector, color, titleStr, treatmentTime, plotType)
    if isempty(data)
        title(sprintf('%s (No Data)', titleStr));
        return;
    end
    
    meanData = mean(data, 1, 'omitnan');
    semData = std(data, 0, 1, 'omitnan') / sqrt(size(data, 1));
    
    hold on;
    if strcmp(plotType, 'mean+sem')
        % Plot SEM using shadedErrorBar
        shadedErrorBar(timeVector, meanData, semData, ...
                      'lineprops', {'Color', color(1:3), 'LineWidth', 2});
    elseif strcmp(plotType, 'mean+individual')
        % Plot individual traces
        for i = 1:size(data, 1)
            plot(timeVector, data(i,:), 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
        end
        % Plot mean on top
        plot(timeVector, meanData, 'Color', color(1:3), 'LineWidth', 2);
    end
    
    % Add treatment line and formatting
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    title(sprintf('%s (n=%d)', titleStr, size(data, 1)));
    ylim([0 inf]);
    xlim([0 5400]);
    grid on;
    hold off;
end

