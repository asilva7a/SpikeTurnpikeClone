function plotTimeLockedPercentChangeCombined(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter, outlierFilter)
    % Set default parameters
    if nargin < 6, outlierFilter = true; end
    if nargin < 5, unitFilter = 'both'; end
    if nargin < 4, plotType = 'mean+sem'; end
    if nargin < 3, treatmentTime = 1860; end
    
    % Define colors for response types
    colors = struct(...
        'Decreased', [0, 0, 1, 0.3], ...     % Blue
        'Increased', [1, 0, 0, 0.3], ...     % Red
        'NoChange', [0.5, 0.5, 0.5, 0.3]);   % Grey
    
    % Process each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            saveDir = fullfile(figureFolder, groupName, recordingName, '0. recordingFigures');
            if ~isfolder(saveDir)
                mkdir(saveDir);
            end
            
            % Get all unique response types from the data
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            responseTypes = {};
            for u = 1:length(units)
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                if isfield(unitData, 'responseType')
                    responseType = strrep(unitData.responseType, ' ', '');
                    if ~ismember(responseType, responseTypes) && ...
                       ~strcmp(responseType, 'MostlySilent') && ...
                       ~strcmp(responseType, 'MostlyZero')
                        responseTypes{end+1} = responseType;
                    end
                end
            end
            
            % Initialize data structures for each response type
            responseData = struct();
            for rt = 1:length(responseTypes)
                responseData.(responseTypes{rt}) = [];
            end
            timeVector = [];
            
            % Collect data by response type
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Apply filters
                if ~isValidUnit(unitData, unitFilter, outlierFilter)
                    continue;
                end
                
                % Process valid units
                if isfield(unitData, 'psthPercentChange') && isfield(unitData, 'responseType')
                    responseType = strrep(unitData.responseType, ' ', '');
                    if ~ismember(responseType, {'MostlySilent', 'MostlyZero'})
                        % Get time vector if not set
                        if isempty(timeVector)
                            timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
                        end
                        
                        % Add data to appropriate response type
                        responseData.(responseType) = [responseData.(responseType); unitData.psthPercentChange];
                    end
                end
            end
            
            % Create figure
            fig = figure('Position', [100, 100, 1600, 500]);
            sgtitle(sprintf('%s - %s - %s (%s units)', groupName, recordingName, plotType, unitFilter));
            
            % Plot each response type
            for rt = 1:length(responseTypes)
                subplot(1, length(responseTypes), rt);
                responseType = responseTypes{rt};
                data = responseData.(responseType);
                
                if ~isempty(data)
                    plotResponseType(timeVector, data, colors.(responseType), ...
                                   responseType, treatmentTime, plotType);
                else
                    title(sprintf('%s (No Data)', responseType));
                end
            end
            
            % Save figure
            saveFigure(fig, saveDir, groupName, recordingName, plotType);
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

function plotResponseType(timeVector, data, color, titleStr, treatmentTime, plotType)
    meanData = mean(data, 1, 'omitnan');
    semData = std(data, 0, 1, 'omitnan') / sqrt(size(data, 1));
    
    if strcmp(plotType, 'mean+individual')
        plot(timeVector, data', 'Color', [color(1:3), 0.1], 'LineWidth', 0.5);
        hold on;
    end
    
    % Plot SEM patch
    patch([timeVector, fliplr(timeVector)], ...
          [meanData + semData, fliplr(meanData - semData)], ...
          color(1:3), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold on;
    
    plot(timeVector, meanData, 'Color', color(1:3), 'LineWidth', 2);
    xline(treatmentTime, '--k', 'Treatment');
    
    title(sprintf('%s (n=%d)', titleStr, size(data, 1)));
    xlabel('Time (s)');
    ylabel('% Change from Baseline');
    grid on;
end

function saveFigure(fig, saveDir, groupName, recordingName, plotType)
    try
        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('%s_%s_%s_timeLockedPercentChangeCombined_%s.fig', ...
                         groupName, recordingName, plotType, timeStamp);
        savefig(fig, fullfile(saveDir, fileName));
        close(fig);
    catch ME
        fprintf('Error saving figure: %s\n', ME.message);
    end
end
