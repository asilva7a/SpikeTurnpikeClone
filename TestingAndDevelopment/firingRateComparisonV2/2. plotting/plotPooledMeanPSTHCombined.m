function cellDataStruct = plotPooledMeanPSTHCombined(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter)
    % plotPooledMeanPSTHCombined: Generates a single figure with three subplots of time-locked mean PSTHs.
    % Pools all units from 'Emx' and 'Pvalb' groups and separates them by response type.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - figureFolder: Directory where the plots will be saved.
    %   - treatmentTime: Time (in seconds) where treatment was administered (for time-locking).
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').

    %% Resolve default args
    % Set default for plotType and unitFilter if not provided
    if nargin < 5
        unitFilter = 'both'; % Default to including both unit types
    end
    if nargin < 4
        plotType = 'mean+sem'; % Default to mean + SEM
    end
    if nargin < 3
        treatmentTime = 1860; % Default treatment time in seconds
    end

    % Define colors for each response type
    colors = struct('Increased', [1, 0, 0, 0.3], ...   % Red with transparency
                    'Decreased', [0, 0, 1, 0.3], ...   % Blue with transparency
                    'NoChange', [0.5, 0.5, 0.5, 0.3]); % Grey with transparency
    
    %% Start data collection
    
    % Initialize arrays for collecting PSTHs by response type across all experimental units
    increasedPSTHs = [];
    decreasedPSTHs = [];
    noChangePSTHs = [];
    timeVector = []; % Initialize in case it needs to be set from data

    % Initialize arrays to store unit IDs by response type
    increasedUnitIDs = {};
    decreasedUnitIDs = {};
    noChangeUnitIDs = {};

    % Loop through 'Emx' and 'Pvalb' groups only, and pool units without separating by recording
    experimentGroups = {'Emx', 'Pvalb'};
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            warning('Group %s not found in cellDataStruct. Skipping.', groupName);
            continue;
        end
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            % Collect individual PSTHs from units based on response type
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Apply unit filter based on IsSingleUnit field
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue; % Skip unit if it doesn't match the filter
                end

                % Proceed if unit has required fields
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2; % Bin centers

                    % Separate by response type
                    switch unitData.responseType
                        case 'Increased'
                            increasedPSTHs = [increasedPSTHs; psth];
                            increasedUnitIDs{end+1} = unitID;
                        case 'Decreased'
                            decreasedPSTHs = [decreasedPSTHs; psth];
                            decreasedUnitIDs{end+1} = unitID;
                        case 'No Change'
                            noChangePSTHs = [noChangePSTHs; psth];
                            noChangeUnitIDs{end+1} = unitID;
                    end
                end
            end
        end
    end

    %% Flag Outlier Units

    % Flag Decreased Units
    if ~isempty(decreasedPSTHs)
        % Calculate the maximum firing rate for each unit in decreasedPSTHs
        maxFiringRates = max(decreasedPSTHs, [], 2);  % Maximum value along each row (unit)
        
        % Define outlier threshold (e.g., using mean + 2*std)
        outlierThreshold = mean(maxFiringRates) + 2 * std(maxFiringRates);
        
        % Identify outlier units
        isOutlier = maxFiringRates > outlierThreshold;
        for i = find(isOutlier)'
            unitID = decreasedUnitIDs{i};
            cellDataStruct = markUnitAsOutlier(cellDataStruct, unitID);
        end
    end

    %% Flag outlier Units
    % Initialize table variables
    flaggedUnits = [];
    flaggedGroup = [];
    flaggedRecording = [];
    flaggedFiringRate = [];
    flaggedStdDev = [];

    % Loop through cellDataStruct to collect information about flagged outliers
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
                if isfield(unitData, 'isOutlier') && unitData.isOutlier
                    flaggedUnits = [flaggedUnits; {unitID}];
                    flaggedGroup = [flaggedGroup; {groupName}];
                    flaggedRecording = [flaggedRecording; {recordingName}];
                    flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
                    flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
                end
            end
        end
    end

    % Print table of flagged units
    flaggedTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.'});
    disp('Flagged Outlier Units:');
    disp(flaggedTable);

    %% Plotting Logic
  
    % Create a figure with three subplots arranged in a 1x3 layout
    figure('Position', [100, 100, 1600, 500]);
    
    % Add the main title for pooled data
    sgtitle(sprintf('Pooled Experimental Units (Emx + Pvalb) - %s', plotType));

    % Plot 1: Positively Modulated Units (Increased)
    subplot(1, 3, 1);
    if ~isempty(increasedPSTHs)
        meanIncreasedPSTH = mean(increasedPSTHs, 1, 'omitnan');
        semIncreasedPSTH = std(increasedPSTHs, 0, 1, 'omitnan') / sqrt(size(increasedPSTHs, 1));
        plotPSTHWithOverlaySubplot(timeVector, meanIncreasedPSTH, semIncreasedPSTH, ...
            increasedPSTHs, colors.Increased, 'Increased', treatmentTime, plotType);
    else
        title('Increased (No Data)');
    end

    % Plot 2: Negatively Modulated Units (Decreased)
    subplot(1, 3, 2);
    if ~isempty(decreasedPSTHs)
        meanDecreasedPSTH = mean(decreasedPSTHs, 1, 'omitnan');
        semDecreasedPSTH = std(decreasedPSTHs, 0, 1, 'omitnan') / sqrt(size(decreasedPSTHs, 1));
        plotPSTHWithOverlaySubplot(timeVector, meanDecreasedPSTH, semDecreasedPSTH, ...
            decreasedPSTHs, colors.Decreased, 'Decreased', treatmentTime, plotType);
    else
        title('Decreased (No Data)');
    end

    % Plot 3: Non-Responsive Units (No Change)
    subplot(1, 3, 3);
    if ~isempty(noChangePSTHs)
        meanNoChangePSTH = mean(noChangePSTHs, 1, 'omitnan');
        semNoChangePSTH = std(noChangePSTHs, 0, 1, 'omitnan') / sqrt(size(noChangePSTHs, 1));
        plotPSTHWithOverlaySubplot(timeVector, meanNoChangePSTH, semNoChangePSTH, ...
            noChangePSTHs, colors.NoChange, 'No Change', treatmentTime, plotType);
    else
        title('No Change (No Data)');
    end

    % Save figure
    saveDir = fullfile(figureFolder, 'PooledSmoothedPSTHs');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    fileName = sprintf('Pooled_Emx_Pvalb_%s_smoothedPSTH_%s.fig', plotType, unitFilter);
    saveas(gcf, fullfile(saveDir, fileName));
    fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));

    close(gcf); % Close to free memory
end
