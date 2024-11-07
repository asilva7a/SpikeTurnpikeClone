function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup)
    % plotFlagOutliersInRecording: Plots the smoothed PSTHs for flagged outliers across response types 
    % and displays a summary table with outlier information for each response type in a 2x3 layout.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data and outlier flags.
    %   - psthDataGroup: Structure containing PSTH data for each response type.
    %   - unitInfoGroup: Structure containing unit information organized by response type.

    % Colors for each response type
    colors = struct('Increased', [1, 0, 0], 'Decreased', [0, 0, 1], 'NoChange', [0.5, 0.5, 0.5]);
    responseTypes = fieldnames(psthDataGroup);

    % Create a figure with a 2x3 layout
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier PSTHs and Summary Table by Response Type');
    
    % Iterate over response types to plot each in a separate subplot
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        psths = psthDataGroup.(responseType);
        
        % Plot the PSTHs for each response type in the top row
        ax = nexttile(t, i);
        hold(ax, 'on');
        xlabel(ax, 'Time (s)');
        ylabel(ax, 'Firing Rate (spikes/s)');
        title(ax, sprintf('Outliers - %s Units', responseType));
        
        % Plot individual PSTHs for outliers
        for j = 1:size(psths, 1)
            plot(ax, psths(j, :), 'Color', colors.(responseType), 'LineWidth', 0.5);
        end
        hold(ax, 'off');
    end

    % Generate and display summary tables in the bottom row, below each PSTH plot
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        flaggedTable = createFlaggedOutlierTable(cellDataStruct, unitInfoGroup.(responseType));
        
        % Create a new table UI for each response type in the bottom row
        axTable = nexttile(t, i + 3);  % Move to the bottom row (offset by 3)
        set(axTable, 'Visible', 'off');  % Hide axis for table display
        uitable('Parent', gcf, 'Data', flaggedTable, 'Units', 'normalized', ...
                'Position', axTable.Position, 'ColumnName', flaggedTable.Properties.VariableNames);
    end
end

function flaggedTable = createFlaggedOutlierTable(cellDataStruct, unitInfo)
    % Helper function to create a summary table of flagged outliers for a specific response type.
    % 
    % Inputs:
    %   - cellDataStruct: Main data structure with unit data.
    %   - unitInfo: Unit information for the specific response type.

    % Initialize table variables
    flaggedUnits = [];
    flaggedGroup = [];
    flaggedRecording = [];
    flaggedFiringRate = [];
    flaggedStdDev = [];

    % Gather outlier information from cellDataStruct using unitInfo
    for i = 1:length(unitInfo)
        unit = unitInfo{i};
        unitData = cellDataStruct.(unit.group).(unit.recording).(unit.id);

        if isfield(unitData, 'isOutlier') && unitData.isOutlier
            flaggedUnits = [flaggedUnits; {unit.id}];
            flaggedGroup = [flaggedGroup; {unit.group}];
            flaggedRecording = [flaggedRecording; {unit.recording}];
            flaggedFiringRate = [flaggedFiringRate; max(unitData.psthSmoothed)];
            flaggedStdDev = [flaggedStdDev; std(unitData.psthSmoothed)];
        end
    end
    
    % Create the summary table
    flaggedTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.'});
end
