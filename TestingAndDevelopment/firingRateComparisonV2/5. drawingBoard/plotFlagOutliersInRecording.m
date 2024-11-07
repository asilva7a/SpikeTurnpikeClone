function plotFlagOutliersInRecording(cellDataStruct,psthDataRecording, unitInfoGroup)
    % plotOutlierPSTHs: Plots the smoothed PSTHs for flagged outliers across response types 
    % and displays a summary table with outlier information in a separate figure.
    %
    % Inputs:
    %   - cellDataStruct: Main data structure containing unit data and outlier flags.
    %   - unitInfoGroup: Structure containing unit information organized by response type.
    
    % --- Debugging defaults ---
    if nargin < 2
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
    % --- End of Debugging Defaults ---

     % Plot the PSTHs for outliers, with response type categorization
    figure;
    t = tiledlayout(2, 1);
    title(t, 'Outlier PSTHs and Summary Table');
    
    ax1 = nexttile(t, 1);
    hold(ax1, 'on');
    xlabel(ax1, 'Time (s)');
    ylabel(ax1, 'Firing Rate (spikes/s)');

    colors = struct('Increased', [1, 0, 0], 'Decreased', [0, 0, 1], 'NoChange', [0.5, 0.5, 0.5]);
    responseTypes = fieldnames(psthDataGroup);
    
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        if ~isempty(psthDataGroup.(responseType))
            for j = 1:size(psthDataGroup.(responseType), 1)
                plot(ax1, psthDataGroup.(responseType)(j, :), 'Color', colors.(responseType), 'LineWidth', 0.5);
            end
        end
    end
    legend(ax1, responseTypes, 'Location', 'northeast');
    hold(ax1, 'off');
    
    % Display summary table in a new axis
    ax2 = nexttile(t, 2);
    set(ax2, 'Visible', 'off');
    flaggedTable = displayFlaggedOutliers(cellDataStruct, 'Experimental');
    uitable('Parent', ax2.Parent, 'Data', flaggedTable, 'Units', 'normalized', ...
            'Position', [0.1, 0.1, 0.8, 0.8]);
end