function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup)
    % plotFlagOutliersInRecording: Plots the smoothed PSTHs for flagged outliers across response types 
    % and displays a summary table as static text within each corresponding plot.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data and outlier flags.
    %   - psthDataGroup: Structure containing PSTH data for each response type.
    %   - unitInfoGroup: Structure containing unit information organized by response type.

    % Colors for each response type
    colors = struct('Increased', [1, 0, 0], 'Decreased', [0, 0, 1], 'NoChange', [0.5, 0.5, 0.5]);
    responseTypes = fieldnames(psthDataGroup);

    % Create a 2x3 layout for plots and summary text
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier PSTHs and Summary Information by Response Type');
    
    % Iterate over response types to plot each in a separate subplot
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        psths = psthDataGroup.(responseType);

        % Plot PSTHs for each response type in the top row
        ax1 = nexttile(t, i);
        hold(ax1, 'on');
        xlabel(ax1, 'Time (s)');
        ylabel(ax1, 'Firing Rate (spikes/s)');
        title(ax1, sprintf('Outliers - %s Units', responseType));
        
        % Plot individual PSTHs for outliers
        for j = 1:size(psths, 1)
            plot(ax1, psths(j, :), 'Color', colors.(responseType), 'LineWidth', 0.5);
        end
        hold(ax1, 'off');
    end

    % Generate and display summary information in the bottom row, below each PSTH plot
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        summaryTable = createFlaggedOutlierTable(cellDataStruct, unitInfoGroup.(responseType));

        % Display table as text in the bottom row
        ax2 = nexttile(t, i + 3);  % Move to the bottom row (offset by 3)
        set(ax2, 'Visible', 'off');  % Hide axis box
        displayTableAsText(ax2, summaryTable);
    end
end

function summaryTable = createFlaggedOutlierTable(cellDataStruct, unitInfo)
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
    summaryTable = table(flaggedUnits, flaggedGroup, flaggedRecording, flaggedFiringRate, flaggedStdDev, ...
        'VariableNames', {'Unit', 'Group', 'Recording', 'Firing Rate', 'Std. Dev.'});
end

function displayTableAsText(ax, summaryTable)
    % displayTableAsText: Renders a table as text in a given axis.
    %
    % Inputs:
    %   - ax: The axis handle where the table will be displayed as text.
    %   - summaryTable: The table containing outlier information to display.

    % Convert table to cell array for easier formatting with text
    tableData = [summaryTable.Properties.VariableNames; table2cell(summaryTable)];
    
    % Format text to display
    tableText = '';
    for i = 1:size(tableData, 1)
        rowText = strjoin(cellfun(@(x) num2str(x), tableData(i, :), 'UniformOutput', false), ' | ');
        tableText = sprintf('%s\n%s', tableText, rowText);
    end
    
    % Display table as multi-line text in the center of the axis
    text(ax, 0.5, 0.5, tableText, 'Units', 'normalized', 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', 'FontSize', 10, 'FontName', 'Courier');
end
