function plotUnitsZScoreByRecording(cellDataStruct, figureFolder)
    % Process each experimental group
    experimentalGroups = {'Emx', 'Pvalb','Control'};
    
    for g = 1:length(experimentalGroups)
        groupName = experimentalGroups{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        % Process each recording
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            
            % Initialize storage for this recording
            recordingPSTHs = [];
            timeVector = [];
            
            % Get units for this recording
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Get time vector from first unit
            firstUnit = cellDataStruct.(groupName).(recordingName).(units{1});
            timeVector = firstUnit.binEdges(1:end-1) + firstUnit.binWidth/2;
            
            % Get baseline period
            baselineIdx = find(timeVector >= 300 & timeVector <= 1800);
            
            % Collect all units' PSTHs for baseline normalization
            allPSTHs = [];
            for u = 1:length(units)
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                if isfield(unitData, 'psthSmoothed')
                    allPSTHs(end+1,:) = unitData.psthSmoothed;
                end
            end
            
            % Calculate recording-wide baseline statistics
            baselineData = allPSTHs(:,baselineIdx);
            recordingBaselineMean = mean(baselineData(:));
            recordingBaselineStd = std(baselineData(:));
            
            % Collect decreased units
            for u = 1:length(units)
                unitData = cellDataStruct.(groupName).(recordingName).(units{u});
                if isfield(unitData, 'responseType') && ...
                   strcmp(strrep(unitData.responseType, ' ', ''), 'Decreased') && ...
                   isfield(unitData, 'psthSmoothed')
                    recordingPSTHs(end+1,:) = unitData.psthSmoothed;
                end
            end
            
            % If there are decreased units, create plot
            if ~isempty(recordingPSTHs)
                % Z-score against recording baseline
                recordingPSTHs_z = (recordingPSTHs - recordingBaselineMean) / recordingBaselineStd;
                
                % Create figure
                fig = figure('Position', [100, 100, 800, 400]);
                
                % Plot z-scored data
                plotRecordingPSTH(recordingPSTHs_z, timeVector, groupName, recordingName);
                
                % Save to appropriate directory
                saveDir = fullfile(figureFolder, groupName, recordingName, '0. recordingFigures');
                if ~isfolder(saveDir)
                    mkdir(saveDir);
                end
                
                savefig(fig, fullfile(saveDir, sprintf('%s_%s_DecreasedUnits_PSTH_Zscored.fig', ...
                    groupName, recordingName)));
                close(fig);
            end
        end
    end
end

function plotRecordingPSTH(psths, timeVector, groupName, recordingName)
    % Set colors based on group
    if strcmp(groupName, 'Emx')
        color = [0 1 1];  % Cyan
    else
        color = [1 0 1];  % Magenta
    end
    
    % Calculate mean and SEM
    meanPSTH = mean(psths, 1);
    semPSTH = std(psths, [], 1) / sqrt(size(psths, 1));
    
    % Plot with shaded error bars
    fill([timeVector, fliplr(timeVector)], ...
         [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
         color, 'FaceAlpha', 0.3, 'EdgeColor', 'none');
    hold on;
    
    % Plot mean
    plot(timeVector, meanPSTH, 'Color', color, 'LineWidth', 2);
    
    % Add treatment time line
    xline(1860, '--k', 'LineWidth', 1.5);
    
    % Calculate trend lines
    baselineIdx = timeVector <= 1860;
    postIdx = timeVector > 1860;
    
    % Baseline trend
    p_baseline = polyfit(timeVector(baselineIdx), meanPSTH(baselineIdx), 1);
    trend_baseline = polyval(p_baseline, timeVector(baselineIdx));
    
    % Post-treatment trend
    p_post = polyfit(timeVector(postIdx), meanPSTH(postIdx), 1);
    trend_post = polyval(p_post, timeVector(postIdx));
    
    % Plot trends
    plot(timeVector(baselineIdx), trend_baseline, '--k', 'LineWidth', 1);
    plot(timeVector(postIdx), trend_post, '--k', 'LineWidth', 1);
    
    % Calculate slopes (Hz/min)
    slope_baseline = p_baseline(1) * 60;
    slope_post = p_post(1) * 60;
    
    % Formatting
    xlabel('Time (s)');
    ylabel('Z-scored Firing Rate');
    title({sprintf('%s %s Decreased Units (n=%d)', groupName, recordingName, size(psths,1)), ...
           sprintf('Trends: Pre=%.2f, Post=%.2f Hz/min', slope_baseline, slope_post)});
    grid on;
    set(gca, 'Layer', 'top', 'GridAlpha', 0.15, 'FontSize', 10);
    
    % Add baseline period statistics
    baselineMean = mean(mean(psths(:,baselineIdx)));
    baselineStd = std(reshape(psths(:,baselineIdx), [], 1));
    text(100, max(ylim)-0.1*range(ylim), ...
         sprintf('Baseline: %.2f ± %.2f Hz', baselineMean, baselineStd), ...
         'FontSize', 10);
end
