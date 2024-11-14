function plotDecreasedUnits(cellDataStruct, ~)
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
    
    % Get time vector from first available unit
    if ~isempty(emxPSTHs)
        timeVector = getTimeVector(cellDataStruct.Emx);
    elseif ~isempty(pvalbPSTHs)
        timeVector = getTimeVector(cellDataStruct.Pvalb);
    end
    
    % Create figure
    fig = figure('Position', [100, 100, 800, 1200]);
    
    % Plot Emx units
    subplot(3,1,1)
    if ~isempty(emxPSTHs)
        plotGroupPSTH(emxPSTHs, timeVector, [0 1 1], 'Emx Decreased Units');  % Cyan
    end
    
    % Plot Pvalb units
    subplot(3,1,2)
    if ~isempty(pvalbPSTHs)
        plotGroupPSTH(pvalbPSTHs, timeVector, [1 0 1], 'Pvalb Decreased Units');  % Pink
    end
    
  % In the combined plot section (subplot(3,1,3)), replace with:
    subplot(3,1,3)
    if ~isempty(emxPSTHs) && ~isempty(pvalbPSTHs)
        % Plot both groups
        plotGroupPSTH(emxPSTHs, timeVector, [0 1 1], 'Combined Units (Emx in cyan, Pvalb in pink)', 0.3);
        hold on;
        plotGroupPSTH(pvalbPSTHs, timeVector, [1 0 1], '', 0.3);
        
        % Perform statistical comparison using larger time windows
        windowSize = 600;  % 10-minute windows for more robust comparison
        samplesPerWindow = round(windowSize / (timeVector(2) - timeVector(1)));
        numWindows = floor(length(timeVector) / samplesPerWindow);
        
        pValues = zeros(1, numWindows);
        sigPoints = false(1, numWindows);
        windowTimes = zeros(1, numWindows);
        
        % Calculate significance threshold
        alpha = 0.01;  % More stringent threshold
        
        % Compare each time window
        for w = 1:numWindows
            startIdx = (w-1)*samplesPerWindow + 1;
            endIdx = min(w*samplesPerWindow, length(timeVector));
            
            % Average firing rate over window
            emxWindow = mean(emxPSTHs(:,startIdx:endIdx), 2);
            pvalbWindow = mean(pvalbPSTHs(:,startIdx:endIdx), 2);
            
            [p] = ranksum(emxWindow, pvalbWindow);
            pValues(w) = p;
            windowTimes(w) = mean(timeVector(startIdx:endIdx));
            sigPoints(w) = p < alpha;
        end
        
        % Plot significance markers
        yLim = ylim;
        yRange = yLim(2) - yLim(1);
        markerY = yLim(2) + 0.05*yRange;
        
        % Plot significance bars with increased visibility
        for w = 1:numWindows
            if sigPoints(w)
                plot([windowTimes(w)-windowSize/2, windowTimes(w)+windowSize/2], ...
                     [markerY markerY], 'k-', 'LineWidth', 4);
            end
        end
        
        % Add legend with statistical information
        sigWindows = sum(sigPoints);
        totalWindows = length(sigPoints);
        legend({'Emx', '', 'Pvalb', '', ...
                sprintf('Significant differences: %d/%d time windows', sigWindows, totalWindows)}, ...
               'Location', 'northeast');
        
        % Update y-limits to show significance bars
        ylim([yLim(1) markerY + 0.1*yRange]);
        
        % Add text showing pre/post treatment differences
        baselinePval = ranksum(mean(emxPSTHs(:,1:1860),2), mean(pvalbPSTHs(:,1:1860),2));
        postPval = ranksum(mean(emxPSTHs(:,1861:end),2), mean(pvalbPSTHs(:,1861:end),2));
        text(100, markerY + 0.05*yRange, ...
             sprintf('Pre-treatment p=%.3e\nPost-treatment p=%.3e', baselinePval, postPval), ...
             'FontSize', 10);
        
        hold off;
    end
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

function plotGroupPSTH(psths, timeVector, color, titleStr, alpha)
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
    ylabel('Firing Rate (Hz)');
    title(sprintf('%s (n=%d)', titleStr, size(psths,1)));
    grid on;
    set(gca, 'Layer', 'top', 'GridAlpha', 0.15, 'FontSize', 10);
end