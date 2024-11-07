function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup)
    % plotFlagOutliersInRecording: Plots the smoothed PSTHs for flagged outliers across response types 
    % and displays a summary table with outlier information below the PSTHs.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data and outlier flags.
    %   - psthDataGroup: Structure containing PSTH data for each response type.
    %   - unitInfoGroup: Structure containing unit information organized by response type.

    % Colors for each response type
    colors = struct('Increased', [1, 0, 0], 'Decreased', [0, 0, 1], 'NoChange', [0.5, 0.5, 0.5]);
    responseTypes = fieldnames(psthDataGroup);
    
    % Create a figure and set up the tiled layout
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(3, 1, 'TileSpacing', 'compact');
    title(t, 'Outlier PSTHs and Summary Table');
    
    % Iterate over response types to plot each in a separate subplot
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        psths = psthDataGroup.(responseType);
        
        % Prepare the subplot
        ax = nexttile(t, i);
        hold(ax, 'on');
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Firing Rate (spikes/s)');
        title(ax, sprintf('Outliers - %s Units', responseType));
        
        % Plot the PSTHs of outliers
        for j = 1:size(psths, 1)
            plot(ax, psths(j, :), 'Color', colors.(responseType), 'LineWidth', 0.5);
        end
        hold(ax, 'off');
    end
    
    % Add a legend with response type labels
    legend(ax, responseTypes, 'Location', 'northeastoutside');

    % Summary table displaying flagged outliers
    flaggedTable = createFlaggedOutlierTable(cellDataStruct, 'Experimental');  % Modify to use 'Recording' as needed
    axTable = nexttile(t, 3, [1, 1]);  % Allocate space for the table
    set(axTable, 'Visible', 'off');  % Hide axis for table display
    
    % Display summary table below plots using uitable
    uitable('Parent', axTable.Parent, 'Data', flaggedTable, 'Units', 'normalized', ...
            'Position', [0.1, 0.05, 0.8, 0.3], 'ColumnName', flaggedTable.Properties.VariableNames);
end

function flaggedTable = createFlaggedOutlierTable(cellDataStruct, level)
    % Helper function to create a table summarizing flagged outliers
    % 
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data and outlier flags.
    %   - level: Level of outlier ('Recording' or 'Experimental') to display.
    
    flaggedUnits = [];
    flaggedGroup = [];
    flaggedRecording = [];
    flaggedFiringRate = [];
    flaggedStdDev = [];

    % Iterate through cellDataStruct to find outliers based on level
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
                
                if (strcmp(level, 'Recording') && isfield(unitData, 'isOutlierRecording') && unitData.isOutlierRecording) || ...
                   (strcmp(level, 'Experimental') && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental)
                    flaggedUnits = [flaggedUnits; {unitID}];
                    flaggedGroup = [flaggedGroup; {groupName}];
                    flaggedRecording = [flaggedRecording; {recordingName}];
                    flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
                    flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
                end
            end
        end
    end
    
    % Construct the table
    flaggedTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.'});
end
