function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, figureFolder)
    % Define colors for the groups
    colors = struct('Emx', [0.8500, 0.3250, 0.0980], ...
                   'Pvalb', [0, 0.4470, 0.7410], ...
                   'Control', [0.4660, 0.6740, 0.1880]);
    
    responseTypes = fieldnames(psthDataGroup);
    experimentGroups = {'Emx', 'Pvalb', 'Control'};

    % Set up figure with a 2x3 tiled layout
    figure('Position', [100, 100, 1600, 800]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(t, 'Outlier Analysis by Response Type');
    
    % Top row: Plot PSTHs of outliers
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        ax1 = nexttile(t, i);
        hold(ax1, 'on');
        title(ax1, sprintf('Outliers - %s Units', responseType));
        xlabel(ax1, 'Time (minutes)');
        ylabel(ax1, 'Firing Rate (Hz)');
        
        % Plot each group's PSTH for outliers only
        for g = 1:length(experimentGroups)
            groupName = experimentGroups{g};
            if ~isfield(unitInfoGroup.(responseType), groupName) || ...
               isempty(unitInfoGroup.(responseType).(groupName))
                continue;
            end
            
            units = unitInfoGroup.(responseType).(groupName);
            for j = 1:length(units)
                unitInfo = units{j};
                unitData = cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id);
                
                if isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    timeVector = (unitData.binEdges(1:end-1) + unitData.binWidth/2)/60; % Convert to minutes
                    plot(ax1, timeVector, unitData.psthSmoothed, ...
                         'Color', [colors.(groupName), 0.7], ...
                         'LineWidth', 1.5);
                end
            end
        end
        
        xlim(ax1, [0, 90]); % Assuming 90-minute recordings
        grid(ax1, 'on');
        hold(ax1, 'off');
    end

    % Bottom row: Plot metric distributions
    metricNames = {'maxFiringRate', 'cv', 'baselineRate'};
    yLabels = {'Max Firing Rate (Hz)', 'Coefficient of Variation', 'Baseline Rate (Hz)'};
    
    for i = 1:length(responseTypes)
        responseType = responseTypes{i};
        ax2 = nexttile(t, i + 3);
        hold(ax2, 'on');
        
        title(ax2, sprintf('Metric Distribution - %s', responseType));
        xlabel(ax2, 'Groups');
        ylabel(ax2, yLabels{1}); % Default to first metric
        
        xPositions = [0.25, 0.75, 1.25];
        for g = 1:length(experimentGroups)
            groupName = experimentGroups{g};
            if ~isfield(psthDataGroup.(responseType), groupName)
                continue;
            end
            
            % Get metric data
            metricData = psthDataGroup.(responseType).(groupName).maxFiringRate;
            if isempty(metricData)
                continue;
            end
            
            % Plot violin or box plot
            xRange = xPositions(g) + [-0.1, 0.1];
            
            % Plot IQR region
            Q1 = prctile(metricData, 25);
            Q3 = prctile(metricData, 75);
            IQR = Q3 - Q1;
            medianVal = median(metricData);
            upperFence = Q3 + 1.5*IQR;
            lowerFence = Q1 - 1.5*IQR;
            
            % Plot IQR box
            fill(ax2, [xRange, fliplr(xRange)], ...
                 [Q1, Q1, Q3, Q3], ...
                 colors.(groupName), 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            
            % Plot median line
            plot(ax2, xRange, [medianVal, medianVal], '-', ...
                 'Color', colors.(groupName), 'LineWidth', 2);
            
            % Plot whiskers
            plot(ax2, mean(xRange)*[1,1], [lowerFence, Q1], '-', ...
                 'Color', colors.(groupName), 'LineWidth', 1);
            plot(ax2, mean(xRange)*[1,1], [Q3, upperFence], '-', ...
                 'Color', colors.(groupName), 'LineWidth', 1);
            
            % Plot individual points for outliers
            outlierIdx = metricData > upperFence | metricData < lowerFence;
            scatter(ax2, repmat(mean(xRange), sum(outlierIdx), 1), ...
                   metricData(outlierIdx), 36, colors.(groupName), ...
                   'filled', 'MarkerFaceAlpha', 0.6);
        end
        
        % Set axis properties
        set(ax2, 'XTick', xPositions, 'XTickLabel', experimentGroups);
        grid(ax2, 'on');
        hold(ax2, 'off');
    end

    % Save figure
    try
        if ~exist(figureFolder, 'dir')
            mkdir(figureFolder);
        end
        timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
        fileName = sprintf('outlierAnalysis_%s.fig', timeStamp);
        savePath = fullfile(figureFolder, fileName);
        savefig(gcf, savePath);
        fprintf('Figure saved to: %s\n', savePath);
    catch ME
        fprintf('Error saving figure: %s\n', ME.message);
    end
end