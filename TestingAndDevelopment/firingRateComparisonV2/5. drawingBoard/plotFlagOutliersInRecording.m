function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs)
    % plotFlagOutliersInRecording: Plots smoothed PSTHs for flagged outliers and displays IQR with points for max firing rates.
    % Each flagged outlier has a unique color across both the PSTH plot and the IQR plot.
    %
    % Inputs:
    %   - cellDataStruct: Structure containing unit data with outlier flags.
    %   - psthDataGroup: Structure with maximum firing rates per response type and group.
    %   - unitInfoGroup: Information about units, organized by response type and group.
    %   - groupIQRs: IQR and outlier thresholds for each response type and group.

    responseTypes = fieldnames(psthDataGroup);
    experimentGroups = {'Emx', 'Pvalb'};  % Define experiment groups locally

    % Set up figure with a 2x3 tiled layout
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier PSTHs and Summary IQR by Response Type');
    
    % Identify total number of outliers to assign unique colors
    numOutliers = 0;
    for i = 1:length(responseTypes)
        for g = 1:length(experimentGroups)
            groupName = experimentGroups{g};
            outliers = unitInfoGroup.(responseTypes{i}).(groupName);
            numOutliers = numOutliers + sum(arrayfun(@(x) isfield(x, 'isOutlierExperimental') && x.isOutlierExperimental, outliers));
        end
    end

  % Generate a large color map with sufficient colors
    colors = parula(numOutliers + 50);  % Add buffer of 50 colors to prevent index overflow
    colorIndex = 1;  % Initialize color index
    outlierColors = containers.Map();
    
    % Assign unique colors only to units flagged as outliers
    for i = 1:length(responseTypes)
    responseType = responseTypes{i};
    
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        outliers = unitInfoGroup.(responseType).(groupName);
        
        for j = 1:length(outliers)
            unitID = outliers{j}.id;
            unitData = cellDataStruct.(groupName).(outliers{j}.recording).(unitID);
            if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                % Ensure colorIndex is within bounds
                colorIndex = mod(colorIndex - 1, size(colors, 1)) + 1;  % Cyclic indexing
                outlierColors(unitID) = colors(colorIndex, :);
                colorIndex = colorIndex + 1;
            end
        end
    end
    end

    % Top row: Plot PSTHs of flagged outliers with unique colors
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        ax1 = nexttile(t, i);
        hold(ax1, 'on');
        title(ax1, sprintf('Outliers - %s Units', responseType));
        xlabel(ax1, 'Time (s)');
        ylabel(ax1, 'Firing Rate (spikes/s)');
        
        % Plot each flagged outlier PSTH with its unique color
        for g = 1:length(experimentGroups)
            groupName = experimentGroups{g};
            outliers = unitInfoGroup.(responseType).(groupName);
            if isempty(outliers)
                continue;
            end
            for j = 1:length(outliers)
                unitID = outliers{j}.id;
                recordingName = outliers{j}.recording;
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    % Retrieve the color for this outlier if it exists
                    if isKey(outlierColors, unitID)
                        color = outlierColors(unitID);
                        plot(ax1, unitData.binEdges(1:end-1) + unitData.binWidth / 2, unitData.psthSmoothed, ...
                             'Color', color, 'LineWidth', 1.5);
                    else
                        fprintf('Debug: Outlier unit %s does not have an assigned color.\n', unitID);
                    end
                end
            end
        end
        hold(ax1, 'off');
    end

    % Bottom row: Plot IQR with max firing rates for each group, using unique colors for flagged outliers
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        ax2 = nexttile(t, i + 3);  % Bottom row
        hold(ax2, 'on');
        title(ax2, sprintf('IQR and Outliers - %s', responseType));
        xlabel(ax2, 'Groups');
        ylabel(ax2, 'Max Firing Rate (spikes/s)');
        
        % Define x-tick positions for groups
        xPositions = [0.25, 0.75];  % Position for Emx and Pvalb groups
        set(ax2, 'XTick', xPositions, 'XTickLabel', {'Emx', 'Pvalb'}); % Set custom x-ticks and labels

        % Plot IQR region and median line for each group
        for g = 1:length(experimentGroups)
            groupName = experimentGroups{g};
            maxRatesGroup = psthDataGroup.(responseType).(groupName);
            if isempty(maxRatesGroup)
                continue;
            end
            
            % Fetch IQR values for the group
            IQR_val = groupIQRs.(responseType).(groupName).IQR;
            median_val = groupIQRs.(responseType).(groupName).Median;
            upperFence = groupIQRs.(responseType).(groupName).UpperFence;
            lowerFence = groupIQRs.(responseType).(groupName).LowerFence;

            % Plot the IQR region with light shading
            xRange = xPositions(g) + [-0.1, 0.1]; % Define x-range for the fill area
            fill(ax2, [xRange, fliplr(xRange)], [repmat(lowerFence, 1, 2), repmat(upperFence, 1, 2)], ...
                 [0.8 0.8 0.8], 'FaceAlpha', 0.3, 'EdgeColor', 'none');  % Gray color for IQR region

            % Plot the median line for the group
            plot(ax2, [xRange(1), xRange(2)], [median_val, median_val], '--', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.5);

            % Plot flagged outlier max firing rates with unique colors as scatter points
            for j = 1:length(maxRatesGroup)
                unitID = unitInfoGroup.(responseType).(groupName){j}.id;
                if isKey(outlierColors, unitID)
                    color = outlierColors(unitID);
                    scatter(ax2, mean(xRange), maxRatesGroup(j), 36, color, 'filled');
                end
            end
        end
        hold(ax2, 'off');
    end
end

