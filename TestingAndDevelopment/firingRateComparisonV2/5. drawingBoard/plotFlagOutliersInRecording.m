function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs)
    % Define colors for each group
    groupColors = struct('Emx', [0, 0.4470, 0.7410], 'Pvalb', [0.8500, 0.3250, 0.0980]);
    responseTypes = fieldnames(psthDataGroup);

    % Create a 2x3 layout for plots and summary information
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier PSTHs and Summary Information by Response Type');
    
    % Top row: Plot individual PSTHs for each response type
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        psths = psthDataGroup.(responseType);

        % Plot PSTHs for each response type in the top row
        ax1 = nexttile(t, i);
        hold(ax1, 'on');
        xlabel(ax1, 'Time (s)');
        ylabel(ax1, 'Firing Rate (spikes/s)');
        title(ax1, sprintf('Outliers - %s Units', responseType));
        
        % Plot individual PSTHs for outliers, color-coded by group
        for j = 1:size(psths, 1)
            unitInfo = unitInfoGroup.(responseType){j};
            groupColor = groupColors.(unitInfo.group);
            plot(ax1, psths(j, :), 'Color', groupColor, 'LineWidth', 0.5);
        end
        hold(ax1, 'off');
    end

    % Bottom row: Plot IQR with outlier max firing rates
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};

        % Retrieve IQR, median, and upper fence for the response type
        emxIQR = groupIQRs.(responseType).Emx.IQR;
        emxMedian = groupIQRs.(responseType).Emx.Median;
        emxUpperFence = groupIQRs.(responseType).Emx.UpperFence;
        pvalbIQR = groupIQRs.(responseType).Pvalb.IQR;
        pvalbMedian = groupIQRs.(responseType).Pvalb.Median;
        pvalbUpperFence = groupIQRs.(responseType).Pvalb.UpperFence;

        % Initialize the plot for IQR in the bottom row
        ax2 = nexttile(t, i + 3);
        hold(ax2, 'on');
        ylabel(ax2, 'Firing Rate (spikes/s)');
        title(ax2, sprintf('Firing Rate IQR - %s Units', responseType));
        
        % Plot IQR as shaded areas
        fill(ax2, [0.9 1.1 1.1 0.9], [emxMedian - emxIQR/2, emxMedian - emxIQR/2, emxMedian + emxIQR/2, emxMedian + emxIQR/2], ...
             groupColors.Emx, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        fill(ax2, [1.9 2.1 2.1 1.9], [pvalbMedian - pvalbIQR/2, pvalbMedian - pvalbIQR/2, pvalbMedian + pvalbIQR/2, pvalbMedian + pvalbIQR/2], ...
             groupColors.Pvalb, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        
        % Plot the median line for each group
        plot(ax2, [0.9 1.1], [emxMedian, emxMedian], 'Color', groupColors.Emx, 'LineWidth', 2);
        plot(ax2, [1.9 2.1], [pvalbMedian, pvalbMedian], 'Color', groupColors.Pvalb, 'LineWidth', 2);
        
        % Plot the upper fence for extreme outliers
        plot(ax2, [0.9 1.1], [emxUpperFence, emxUpperFence], '--', 'Color', groupColors.Emx, 'LineWidth', 1.5);
        plot(ax2, [1.9 2.1], [pvalbUpperFence, pvalbUpperFence], '--', 'Color', groupColors.Pvalb, 'LineWidth', 1.5);

        % Overlay max firing rates for flagged outliers as individual points
        emxRates = [];
        pvalbRates = [];
        for j = 1:length(unitInfoGroup.(responseType))
            unitInfo = unitInfoGroup.(responseType){j};
            maxRate = max(cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).psthSmoothed);
            if strcmp(unitInfo.group, 'Emx')
                emxRates = [emxRates; maxRate];
            elseif strcmp(unitInfo.group, 'Pvalb')
                pvalbRates = [pvalbRates; maxRate];
            end
        end
        scatter(ax2, ones(size(emxRates)), emxRates, 25, groupColors.Emx, 'filled');
        scatter(ax2, 2 * ones(size(pvalbRates)), pvalbRates, 25, groupColors.Pvalb, 'filled');
        
        hold(ax2, 'off');
        set(ax2, 'XTick', [1, 2], 'XTickLabel', {'Emx', 'Pvalb'}, 'XLim', [0.5 2.5]);
    end
end
