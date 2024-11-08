function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs)
    % plotFlagOutliersInRecording: Plots smoothed PSTHs for flagged outliers and displays IQR with points for max firing rates.
    %
    % Inputs:
    %   - cellDataStruct: Structure containing unit data with outlier flags.
    %   - psthDataGroup: Structure with maximum firing rates per response type and group.
    %   - unitInfoGroup: Information about units, organized by response type and group.
    %   - groupIQRs: IQR and outlier thresholds for each response type and group.

    colors = struct('Emx', [0.8500, 0.3250, 0.0980], 'Pvalb', [0, 0.4470, 0.7410]); % Color scheme for groups
    responseTypes = fieldnames(psthDataGroup);
    experimentGroups = {'Emx', 'Pvalb'}; % Define experiment groups locally

    % Set up figure with a 2x3 tiled layout
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier PSTHs and Summary IQR by Response Type');
    
    % Top row: Plot PSTHs of outliers
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        ax1 = nexttile(t, i);
        hold(ax1, 'on');
        title(ax1, sprintf('Outliers - %s Units', responseType));
        xlabel(ax1, 'Time (s)');
        ylabel(ax1, 'Firing Rate (spikes/s)');
        
        % Plot each group's PSTH for outliers only
        for g = fieldnames(colors)'
            groupName = g{1};
            outliers = unitInfoGroup.(responseType).(groupName);
            if isempty(outliers)
                continue;
            end
            for j = 1:length(outliers)
                unitID = outliers{j}.id;
                recordingName = outliers{j}.recording;
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    plot(ax1, unitData.binEdges(1:end-1) + unitData.binWidth / 2, unitData.psthSmoothed, ...
                         'Color', colors.(groupName), 'LineWidth', 1.5);
                end
            end
        end
        hold(ax1, 'off');
    end

    % Bottom row: Plot IQR with max firing rates for each group
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        ax2 = nexttile(t, i + 3);  % Bottom row
        hold(ax2, 'on');
        title(ax2, sprintf('IQR and Outliers - %s', responseType));
        xlabel(ax2, 'Groups');
        ylabel(ax2, 'Max Firing Rate (spikes/s)');
        
        % Plot IQR region and median line for each group
        xPositions = [0.25, 0.75]; % Fixed x-positions for Emx and Pvalb groups
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

            % Plot the IQR region with specified color and transparency
            xRange = xPositions(g) + [-0.1, 0.1]; % Define x-range for the fill area
            fill(ax2, [xRange, fliplr(xRange)], [repmat(lowerFence, 1, 2), repmat(upperFence, 1, 2)], ...
                 colors.(groupName), 'FaceAlpha', 0.2, 'EdgeColor', 'none');

            % Plot the median line for the group
            plot(ax2, [xRange(1), xRange(2)], [median_val, median_val], '--', 'Color', colors.(groupName), 'LineWidth', 1.5);

            % Plot individual max firing rates as scatter points
            scatter(ax2, repmat(mean(xRange), size(maxRatesGroup)), maxRatesGroup, 36, colors.(groupName), 'filled');
        end
        hold(ax2, 'off');
    end
end

