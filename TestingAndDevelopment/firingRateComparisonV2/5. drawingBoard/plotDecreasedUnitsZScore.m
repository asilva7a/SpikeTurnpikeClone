function plotDecreasedUnitsZScore(cellDataStruct, figureFolder)
    % Initialize storage for different groups
    emxPSTHs = [];
    pvalbPSTHs = [];
    timeVector = [];
    
    % Extract data
    if isfield(cellDataStruct, 'Emx')
        emxPSTHs = extractGroupPSTHs(cellDataStruct.Emx);
    end
    
    if isfield(cellDataStruct, 'Pvalb')
        pvalbPSTHs = extractGroupPSTHs(cellDataStruct.Pvalb);
    end
    
    % Get time vector
    if ~isempty(emxPSTHs)
        timeVector = getTimeVector(cellDataStruct.Emx);
    elseif ~isempty(pvalbPSTHs)
        timeVector = getTimeVector(cellDataStruct.Pvalb);
    end
    
    % Calculate baseline period indices
    baselineIdx = 1:find(timeVector <= 1860, 1, 'last');
    
    % Z-score against group baselines
    emxPSTHs_z = zscore_against_group_baseline(emxPSTHs, baselineIdx);
    pvalbPSTHs_z = zscore_against_group_baseline(pvalbPSTHs, baselineIdx);
    % Create figure
    fig = figure('Position', [100, 100, 800, 1200]);
    
    % Plot Emx units (z-scored)
    subplot(3,1,1)
    if ~isempty(emxPSTHs_z)
        plotGroupPSTH(emxPSTHs_z, timeVector, [0 1 1], 'Emx Decreased Units (Z-scored)');
    end
    
    % Plot Pvalb units (z-scored)
    subplot(3,1,2)
    if ~isempty(pvalbPSTHs_z)
        plotGroupPSTH(pvalbPSTHs_z, timeVector, [1 0 1], 'Pvalb Decreased Units (Z-scored)');
    end
    
    % Plot combined with statistical comparison
    subplot(3,1,3)
    if ~isempty(emxPSTHs_z) && ~isempty(pvalbPSTHs_z)
        % Plot both groups with explicit colors
        plotGroupPSTH(emxPSTHs_z, timeVector, [0 1 1], 'Combined Units (Z-scored)', 0.3);
        hold on;
        plotGroupPSTH(pvalbPSTHs_z, timeVector, [1 0 1], '', 0.3);
        
        % Statistical comparison using time windows
        windowSize = 300;  % 5-minute windows
        samplesPerWindow = round(windowSize / (timeVector(2) - timeVector(1)));
        numWindows = floor(length(timeVector) / samplesPerWindow);
        
        pValues = zeros(1, numWindows);
        sigPoints = false(1, numWindows);
        windowTimes = zeros(1, numWindows);
        
        % Compare each time window
        for w = 1:numWindows
            startIdx = (w-1)*samplesPerWindow + 1;
            endIdx = min(w*samplesPerWindow, length(timeVector));
            
            emxWindow = mean(emxPSTHs_z(:,startIdx:endIdx), 2);
            pvalbWindow = mean(pvalbPSTHs_z(:,startIdx:endIdx), 2);
            
            [p] = ranksum(emxWindow, pvalbWindow);
            pValues(w) = p;
            windowTimes(w) = mean(timeVector(startIdx:endIdx));
            sigPoints(w) = p < 0.01;
        end
        
        % Plot significance markers
        yLim = ylim;
        yRange = yLim(2) - yLim(1);
        markerY = yLim(2) + 0.05*yRange;
        
        for w = 1:numWindows
            if sigPoints(w)
                plot([windowTimes(w)-windowSize/2, windowTimes(w)+windowSize/2], ...
                     [markerY markerY], 'k-', 'LineWidth', 4);
            end
        end
        
        % Add legend
        sigWindows = sum(sigPoints);
        legend({'Emx', '', 'Pvalb', '', ...
                sprintf('Significant differences: %d/%d windows', sigWindows, numWindows)}, ...
               'Location', 'northeast');
        
        % Update y-limits
        ylim([yLim(1) markerY + 0.1*yRange]);
        ylabel('Z-scored Firing Rate');
        
        hold off;
    end

    
    % Save figure
    saveDir = fullfile(figureFolder, '0. expFigures');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    savefig(fig, fullfile(saveDir, 'DecreasedUnits_PSTH_Zscored.fig'));
    close(fig);
end

function zscoredData = zscore_against_group_baseline(psths, baselineIdx)
    % Calculate group baseline statistics
    groupBaselineMean = mean(mean(psths(:,baselineIdx)));
    groupBaselineStd = std(reshape(psths(:,baselineIdx), [], 1));
    
    % Z-score all units using group baseline statistics
    zscoredData = (psths - groupBaselineMean) / groupBaselineStd;
end

function plotGroupPSTH(psths, timeVector, color, titleStr, alpha, baselineStats)
    if nargin < 5
        alpha = 0.3;
    end
    
    % Calculate mean and SEM
    meanPSTH = mean(psths, 1);
    semPSTH = std(psths, [], 1) / sqrt(size(psths, 1));
    
    % Plot with shaded error bars
    fill([timeVector, fliplr(timeVector)], ...
         [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
         color, 'FaceAlpha', alpha, 'EdgeColor', 'none');
    hold on;
    plot(timeVector, meanPSTH, 'Color', color, 'LineWidth', 2);
    
    % Add treatment time line
    xline(1860, '--k', 'LineWidth', 1.5);
    
    % Formatting
    xlabel('Time (s)');
    ylabel('Z-scored Firing Rate');
    
    % Add title with group baseline information
    if ~isempty(titleStr)
        baselineIdx = 1:find(timeVector <= 1860, 1, 'last');
        groupBaselineMean = mean(mean(psths(:,baselineIdx)));
        groupBaselineStd = std(reshape(psths(:,baselineIdx), [], 1));
        
        title({sprintf('%s (n=%d)', titleStr, size(psths,1)), ...
               sprintf('Group Baseline: %.2f ± %.2f Hz', groupBaselineMean, groupBaselineStd)}, ...
              'FontSize', 10);
    end
    
    grid on;
    set(gca, 'Layer', 'top', 'GridAlpha', 0.15, 'FontSize', 10);
end

function psths = extractGroupPSTHs(groupData)
    psths = [];
    recordings = fieldnames(groupData);
    
    for r = 1:length(recordings)
        units = fieldnames(groupData.(recordings{r}));
        for u = 1:length(units)
            unitData = groupData.(recordings{r}).(units{u});
            if isfield(unitData, 'responseType') && ...
               strcmp(strrep(unitData.responseType, ' ', ''), 'Decreased') && ...
               isfield(unitData, 'psthSmoothed')
                psths(end+1,:) = unitData.psthSmoothed;
            end
        end
    end
end

function timeVector = getTimeVector(groupData)
    recordings = fieldnames(groupData);
    units = fieldnames(groupData.(recordings{1}));
    unitData = groupData.(recordings{1}).(units{1});
    timeVector = unitData.binEdges(1:end-1) + unitData.binWidth/2;
end
