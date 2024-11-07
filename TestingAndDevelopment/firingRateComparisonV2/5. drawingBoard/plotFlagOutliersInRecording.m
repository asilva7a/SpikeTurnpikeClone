function cellDataStruct = plotFlagOutliersInRecording(cellDataStruct, plotOutliers, figureFolder)
    % flagOutliersInRecording: Flags units as outliers within each recording based on their PSTH area under the curve (AUC).
    % Optionally plots and saves the smoothed PSTH of outlier units.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - plotOutliers (optional): Boolean flag to plot and save outlier PSTHs. Default is false.
    %   - figureFolder (optional): Directory in which to save outlier plots. Default is 'outlierUnitsAUCFilter' within current directory.
    %
    % Outputs:
    %   - cellDataStruct: Updated data structure with `isOutlier` field added to each unit.

    if nargin < 2
        plotOutliers = false; % Default value
    end
    if nargin < 3
        figureFolder = 'outlierUnitsAUCFilter';
    end

    % Define the subdirectory to save outlier plots
    outlierPlotFolder = fullfile(figureFolder, 'outlierUnitsAUCFilter');
    if plotOutliers
        if ~exist(outlierPlotFolder, 'dir')
            mkdir(outlierPlotFolder);
        end
    end

    % Initialize cell array to collect outlier information for the table
    outlierInfo = {'Unit', 'Group', 'Recording', 'AUC', 'Std. Dev.'};

    % Loop through each group and recording
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        for r = 1:length(recordings)
            recordingName = recordings{r};
            
            % Initialize arrays for collecting AUCs by response type
            increasedAUCs = [];
            decreasedAUCs = [];
            noChangeAUCs = [];
            
            % Collect individual PSTHs and corresponding unit IDs for each response type
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            increasedUnitIDs = {};
            decreasedUnitIDs = {};
            noChangeUnitIDs = {};
            
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Check if the unit has required fields
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    auc = trapz(psth);  % Compute the area under the curve
                    
                    % Sort the units by their response type
                    switch unitData.responseType
                        case 'Increased'
                            increasedAUCs = [increasedAUCs; auc];
                            increasedUnitIDs{end+1} = unitID; %#ok<AGROW>
                        case 'Decreased'
                            decreasedAUCs = [decreasedAUCs; auc];
                            decreasedUnitIDs{end+1} = unitID; %#ok<AGROW>
                        case 'No Change'
                            noChangeAUCs = [noChangeAUCs; auc];
                            noChangeUnitIDs{end+1} = unitID; %#ok<AGROW>
                    end
                end
            end
            
            % Flag outliers for each response type
            [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, increasedUnitIDs, increasedAUCs, 'Increased', outlierInfo, plotOutliers, outlierPlotFolder);
            [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, decreasedUnitIDs, decreasedAUCs, 'Decreased', outlierInfo, plotOutliers, outlierPlotFolder);
            [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, noChangeUnitIDs, noChangeAUCs, 'No Change', outlierInfo, plotOutliers, outlierPlotFolder);
        end
    end

    % Convert outlier information to a table and display it
    if size(outlierInfo, 1) > 1  % Check if there are any outliers
        outlierTable = cell2table(outlierInfo(2:end, :), 'VariableNames', outlierInfo(1, :));
        disp('Outlier Units Table:');
        disp(outlierTable);
    else
        disp('No outlier units detected.');
    end
end

%% Helper Function: Flag outliers for a specific response type and collect information
function [cellDataStruct, outlierInfo] = flagOutliersForCategory(cellDataStruct, groupName, recordingName, unitIDs, aucValues, responseType, outlierInfo, plotOutliers, outlierPlotFolder)
    % flagOutliersForCategory: Flags units as outliers for a specific response type within a recording.
    %
    % Inputs:
    %   - cellDataStruct: Data structure to be updated
    %   - groupName: Name of the group
    %   - recordingName: Name of the recording
    %   - unitIDs: Cell array of unit IDs for this response type
    %   - aucValues: Array of AUC values for this response type
    %   - responseType: String specifying the response type ('Increased', 'Decreased', 'No Change')
    %   - outlierInfo: Cell array to collect outlier information for printing a summary table
    %   - plotOutliers: Boolean flag to plot and save outlier PSTHs
    %   - outlierPlotFolder: Folder to save the outlier plots
    %
    % Outputs:
    %   - cellDataStruct: Updated data structure with `isOutlier` field for outliers in the specified category
    %   - outlierInfo: Updated cell array with outlier information

    if isempty(aucValues)
        return; % No data for this response type, skip
    end

    % Define outlier threshold (e.g., mean + 2*std)
    meanAUC = mean(aucValues);
    stdAUC = std(aucValues);
    outlierThreshold = meanAUC + 2 * stdAUC;
    
    % Identify outliers based on AUC
    isOutlier = aucValues > outlierThreshold;
    outlierIndices = find(isOutlier);
    
    % Update cellDataStruct to mark outliers
    for i = 1:length(outlierIndices)
        unitIdx = outlierIndices(i);
        unitID = unitIDs{unitIdx};
        
        % Set the `isOutlier` field for this unit to true
        cellDataStruct.(groupName).(recordingName).(unitID).isOutlier = true;
        
        % Collect outlier information for display
        aucValue = aucValues(unitIdx);
        outlierInfo{end+1, 1} = unitID;
        outlierInfo{end, 2} = groupName;
        outlierInfo{end, 3} = recordingName;
        outlierInfo{end, 4} = aucValue;       % AUC
        outlierInfo{end, 5} = stdAUC;         % Std. Dev.
        
        % Plot and save the outlier if requested
        if plotOutliers
            unitData = cellDataStruct.(groupName).(recordingName).(unitID);
            plotAndSaveOutlierPSTH(unitData.psthSmoothed, unitID, groupName, recordingName, aucValue, stdAUC, outlierPlotFolder);
        end
    end
    
    % For non-outliers in this category, ensure `isOutlier` field is set to false
    nonOutlierIndices = find(~isOutlier);
    for i = 1:length(nonOutlierIndices)
        unitIdx = nonOutlierIndices(i);
        unitID = unitIDs{unitIdx};
        
        % Set the `isOutlier` field for this unit to false
        cellDataStruct.(groupName).(recordingName).(unitID).isOutlier = false;
    end
end

%% Helper Function: Plot and save the outlier PSTH with annotations
function plotAndSaveOutlierPSTH(psthSmoothed, unitID, groupName, recordingName, aucValue, stdAUC, outlierPlotFolder)
    % plotAndSaveOutlierPSTH: Plots and saves the smoothed PSTH of an outlier unit.
    %
    % Inputs:
    %   - psthSmoothed: Smoothed PSTH data for the unit
    %   - unitID: Identifier for the unit
    %   - groupName: Name of the group
    %   - recordingName: Name of the recording
    %   - aucValue: AUC value of the unit
    %   - stdAUC: Standard deviation of AUC for the category
    %   - outlierPlotFolder: Folder to save the plot

    figure;
    plot(psthSmoothed, 'LineWidth', 2);
    title(sprintf('PSTH for Unit %s | Group: %s, Recording: %s', unitID, groupName, recordingName));
    xlabel('Time (ms)');
    ylabel('Firing Rate (spikes/s)');
    
    % Annotate with outlier information
    annotationText = sprintf('AUC:      %.2f | Std Dev: %.2f', aucValue, stdAUC);
    annotation('textbox', [0.15, 0.01, 0.7, 0.1], 'String', annotationText, 'HorizontalAlignment', 'center', ...
               'EdgeColor', 'none', 'FontSize', 10);

    try
    saveas(gcf, fullfile(outlierPlotFolder, sprintf('%s_%s_%s.fig', groupName, recordingName, unitID)));
    disp(['Saved file: ', fullfile(outlierPlotFolder, sprintf('%s_%s_%s.fig', groupName, recordingName, unitID))]);
    catch ME
    warning(['Failed to save file for Unit: ', unitID, '. Error: ', ME.message]);
    end

    close;

end

