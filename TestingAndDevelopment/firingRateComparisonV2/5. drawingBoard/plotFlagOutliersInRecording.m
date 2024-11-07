function plotOutlierPSTHs(cellDataStruct, responseTypes, unitInfoGroup)
    % plotOutlierPSTHs: Plots the smoothed PSTHs for flagged outliers across response types 
    % and displays a summary table with outlier information in a separate figure.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data and outlier flags.
    %   - responseTypes: Cell array of response types (e.g., {'Increased', 'Decreased', 'NoChange'}).
    %   - unitInfoGroup: Structure containing unit information organized by response type.

    % --- Debugging defaults ---
    if nargin < 3
        unitInfoGroup = struct();
        unitInfoGroup.Increased = {};
        unitInfoGroup.Decreased = {};
        unitInfoGroup.NoChange = {};

        % Load or initialize a sample cellDataStruct if not provided
        try
            load('/path/to/sample/cellDataStruct.mat'); % Replace with your sample file path
            fprintf('Debug: Loaded default cellDataStruct from file.\n');
        catch
            error('Error loading cellDataStruct for debugging.');
        end
    end
    if nargin < 2
        responseTypes = {'Increased', 'Decreased', 'NoChange'};
    end
    % --- End of Debugging Defaults ---

    % Define colors for each response type
    colors = struct('Increased', [1, 0, 0], 'Decreased', [0, 0, 1], 'NoChange', [0.5, 0.5, 0.5]);
    
    % Create a new figure for plotting
    figure('Position', [100, 100, 1600, 600]);
    t = tiledlayout(1, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier PSTHs by Response Type');
    
    % Create axes for the PSTH plots
    ax1 = nexttile(t);
    hold(ax1, 'on');
    xlabel(ax1, 'Time (s)');
    ylabel(ax1, 'Firing Rate (spikes/s)');
    
    % Loop through each response type and plot the flagged PSTHs
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};  % Get response type as a string
        
        % Get the list of outliers for this response type
        flaggedUnits = unitInfoGroup.(responseType);
        
        % Plot each outlier PSTH with the assigned color
        for j = 1:length(flaggedUnits)
            unitInfo = flaggedUnits{j};
            psth = cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).psthSmoothed;
            plot(ax1, psth, 'Color', colors.(responseType), 'LineWidth', 1);
        end
    end
    
    % Set legend for response types
    legend(ax1, responseTypes, 'Location', 'northeast');
    hold(ax1, 'off');
    
    % Display summary table in a separate figure
    figure('Position', [100, 700, 800, 300]);
    summaryTable = compileOutlierSummaryTable(cellDataStruct); % Generate summary table data
    uitable('Data', summaryTable, 'Units', 'normalized', 'Position', [0, 0, 1, 1]); % Display the table in the figure
end




