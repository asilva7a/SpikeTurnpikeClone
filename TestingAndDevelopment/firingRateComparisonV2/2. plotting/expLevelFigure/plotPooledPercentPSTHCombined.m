function plotPooledPercentPSTHCombined(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter, outlierFilter)
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
    
    % Initialize data collection
    responseData = struct(...
        'Increased', [], ...
        'Decreased', [], ...
        'NoChange', [], ...
        'timeVector', []);
    
    % Create save directory
    saveDir = fullfile(figureFolder, '0. expFigures');
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
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Process units
            for u = 1:length(units)
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                
                % Check unit validity
                if ~isValidUnit(unitData, unitFilter, outlierFilter)
                    continue;
                end
                
                % Process valid unit
                responseData = processUnit(unitData, responseData);
            end
        end
    end
    
    % Create and save figure if data exists
    if ~isempty(responseData.timeVector)
        createAndSaveFigure(responseData, treatmentTime, plotType, COLORS, saveDir);
    else
        warning('Plot:NoData', 'No valid units found for plotting');
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
    isValid = isfield(unitData, 'psthPercentChange') && ...
              isfield(unitData, 'responseType') && ...
              isfield(unitData, 'binEdges') && ...
              isfield(unitData, 'binWidth');
end

function responseData = processUnit(unitData, responseData)
    % Get time vector if not set
    if isempty(responseData.timeVector)
        responseData.timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
    end
    
    % Add data to appropriate response type
    responseType = strrep(unitData.responseType, ' ', '');
    if isfield(responseData, responseType)
        responseData.(responseType) = [responseData.(responseType); unitData.psthPercentChange];
    end
end

function createAndSaveFigure(responseData, treatmentTime, plotType, colors, saveDir)
    fig = figure('Position', [100, 100, 1600, 500]);
    sgtitle(sprintf('Pooled Emx and Pvalb - %s', plotType));
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    for i = 1:length(responseTypes)
        subplot(1, 3, i);
        plotResponseType(responseData.(responseTypes{i}), responseData.timeVector, ...
                        colors.(responseTypes{i}), responseTypes{i}, ...
                        treatmentTime, plotType);
    end
    
    % Save figure
    try
        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('Pooled_Emx_Pvalb_%s_percentChangePSTH_%s.fig', plotType, timeStamp);
        savefig(fig, fullfile(saveDir, fileName));
        close(fig);
    catch ME
        warning('Save:Error', 'Error saving figure: %s', ME.message);
    end
end

function plotResponseType(data, timeVector, color, plotTitle, treatmentTime, plotType)
    if isempty(data)
        title(sprintf('%s (No Data)', plotTitle));
        return;
    end
    
    meanData = mean(data, 1, 'omitnan');
    semData = std(data, 0, 1, 'omitnan') / sqrt(size(data, 1));
    
    hold on;
    if strcmp(plotType, 'mean+sem')
        shadedErrorBar(timeVector, meanData, semData, ...
                      'lineprops', {'Color', color(1:3), 'LineWidth', 2});
    elseif strcmp(plotType, 'mean+individual')
        plot(timeVector, data', 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
        plot(timeVector, meanData, 'Color', color(1:3), 'LineWidth', 2);
    end
    
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Firing Rate Percent Change (%)');
    title(sprintf('%s (n=%d)', plotTitle, size(data, 1)));
    ylim([0 inf]);
    xlim([0 5400]);
    grid on;
    hold off;
end
