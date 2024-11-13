function [cellDataStruct, sparseUnitsList] = tagSparseUnits(cellDataStruct, binWidth, minFrRate, dataFolder)
    % tagSparseUnits Tags units with specific firing patterns
    % Inputs:
    %   cellDataStruct: Nested structure containing unit data
    %   binWidth: Width of time bins in seconds
    %   minFrRate: Minimum firing rate threshold (default 0.5 Hz)
    %   dataFolder: Optional path for saving results
    % Outputs:
    %   cellDataStruct: Updated structure with tagged units
    %   sparseUnitsList: Table containing identified units
    
    % Set default args
    if nargin < 3 || isempty(minFrRate)
        minFrRate = 0.5;
    end
    
    % Validate bin width
    if binWidth <= 0
        error('Bin width must be positive');
    end
    
    % Add warning for very small or large bins
    if binWidth < 1
        warning('Small bin width (<1s) may affect detection sensitivity');
    elseif binWidth > 60
        warning('Large bin width (>60s) may miss brief square waves');
    end
    
    % Get total number of units for table initialization
    numFields = 0;
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
            numFields = numFields + length(units);
        end
    end
    
    % Modified table structure to handle square waves
    unitTable = table('Size', [numFields, 7], ...
                      'VariableTypes', {'string', 'string', 'string', ...
                                        'logical', 'cell', 'cell', 'cell'}, ...
                      'VariableNames', {'unitID', 'recordingName', 'groupName', ...
                                        'hasSquareWave', 'squareWaveStartTimes', ...
                                        'squareWaveDurations', 'squareWaveAmplitudes'});
    
    % Initialize counter for table rows
    rowCounter = 1;
    minutesToSecs = 60;

    % Loop through groups, recordings, and units
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Get PSTH data
                psthData = unitData.psthSmoothed;
                timeVector = unitData.binEdges(1:end-1) + binWidth/2;
                timeInMinutes = timeVector/minutesToSecs;
                
                % Square wave detection parameters
                windowSize = 3;    % minutes
                stepSize = 0.5;    % minutes
                minSquareDuration = 1;  % minutes
                maxSquareWaves = 10;
                cv_threshold = 0.2;
                
                % Convert time windows to indices
                pointsPerMin = round(minutesToSecs/binWidth);
                windowPoints = round(windowSize * pointsPerMin);
                stepPoints = round(stepSize * pointsPerMin);
                
                % Initialize arrays for multiple square waves
                squareWaves = struct('startTime', [], 'duration', [], 'amplitude', []);
                hasSquareWave = false;
                
                % Scan through recording
                for startIdx = 1:stepPoints:length(psthData)-windowPoints
                    endIdx = startIdx + windowPoints - 1;
                    windowData = psthData(startIdx:endIdx);
                    windowTime = timeInMinutes(startIdx:endIdx);
                    
                    % Calculate metrics
                    meanRate = mean(windowData);
                    cv = std(windowData)/meanRate;
                    
                    % Check for square wave characteristics
                    if meanRate > 0.2 && cv < cv_threshold
                        if startIdx > 1 && endIdx < length(psthData)
                            beforeRate = mean(psthData(max(1,startIdx-3):startIdx-1));
                            afterRate = mean(psthData(endIdx+1:min(length(psthData),endIdx+3)));
                            
                            onsetRatio = meanRate/max(beforeRate, eps);
                            offsetRatio = meanRate/max(afterRate, eps);
                            
                            if onsetRatio > 2 && offsetRatio > 2 && ...
                               (windowTime(end)-windowTime(1)) >= minSquareDuration
                                
                                % Check if this period overlaps with existing ones
                                isOverlapping = false;
                                if ~isempty(squareWaves.startTime)
                                    for w = 1:length(squareWaves.startTime)
                                        waveEnd = squareWaves.startTime(w) + squareWaves.duration(w);
                                        if (windowTime(1) >= squareWaves.startTime(w) && windowTime(1) <= waveEnd) || ...
                                           (windowTime(end) >= squareWaves.startTime(w) && windowTime(end) <= waveEnd)
                                            isOverlapping = true;
                                            break;
                                        end
                                    end
                                end
                                
                                if ~isOverlapping
                                    hasSquareWave = true;
                                    squareWaves.startTime(end+1) = windowTime(1);
                                    squareWaves.duration(end+1) = windowTime(end)-windowTime(1);
                                    squareWaves.amplitude(end+1) = meanRate;
                                    
                                    if length(squareWaves.startTime) >= maxSquareWaves
                                        break;
                                    end
                                end
                            end
                        end
                    end
                end
                
                % Store results in table
                unitTable.unitID(rowCounter) = string(unitID);
                unitTable.recordingName(rowCounter) = string(recordingName);
                unitTable.groupName(rowCounter) = string(groupName);
                unitTable.hasSquareWave(rowCounter) = hasSquareWave;
                unitTable.squareWaveStartTimes{rowCounter} = squareWaves.startTime;
                unitTable.squareWaveDurations{rowCounter} = squareWaves.duration;
                unitTable.squareWaveAmplitudes{rowCounter} = squareWaves.amplitude;
                
                % Update unit structure
                cellDataStruct.(groupName).(recordingName).(unitID).hasSquareWave = hasSquareWave;
                if hasSquareWave
                    cellDataStruct.(groupName).(recordingName).(unitID).squareWaves = squareWaves;
                    fprintf('Found square waves in unit %s:\n', unitID);
                    for w = 1:length(squareWaves.startTime)
                        fprintf('  Wave %d: %.1f-%.1f minutes, %.2f Hz\n', ...
                            w, squareWaves.startTime(w), ...
                            squareWaves.startTime(w) + squareWaves.duration(w), ...
                            squareWaves.amplitude(w));
                    end
                    fprintf('\n');
                end
                
                rowCounter = rowCounter + 1;
            end
        end
    end

    % Trim any unused rows from the table
    unitTable = unitTable(1:rowCounter-1, :);

    % Create output table of identified units
    sparseUnitsList = unitTable(unitTable.hasSquareWave, :);
    
    % Sort and visualize results
    if ~isempty(sparseUnitsList)
        sparseUnitsList = sortrows(sparseUnitsList, 'hasSquareWave', 'descend');
        
        figure('Position', [100 100 800 600]);
        for i = 1:min(5, height(sparseUnitsList))
            unitID = sparseUnitsList.unitID(i);
            groupName = sparseUnitsList.groupName(i);
            recordingName = sparseUnitsList.recordingName(i);
            
            psthData = cellDataStruct.(groupName).(recordingName).(unitID).psthSmoothed;
            timeVector = cellDataStruct.(groupName).(recordingName).(unitID).binEdges(1:end-1) + binWidth/2;
            timeInMinutes = timeVector/minutesToSecs;
            
            subplot(min(5, height(sparseUnitsList)), 1, i);
            plot(timeInMinutes, psthData, 'LineWidth', 1.5);
            
            squareWaves = cellDataStruct.(groupName).(recordingName).(unitID).squareWaves;
            titleStr = sprintf('Unit %s (Square waves: n=%d)', ...
                char(unitID), length(squareWaves.startTime));
            
            % Highlight square wave periods
            hold on;
            ylims = ylim;
            for w = 1:length(squareWaves.startTime)
                patch([squareWaves.startTime(w), ...
                       squareWaves.startTime(w) + squareWaves.duration(w), ...
                       squareWaves.startTime(w) + squareWaves.duration(w), ...
                       squareWaves.startTime(w)], ...
                      [ylims(1) ylims(1) ylims(2) ylims(2)], ...
                      'y', 'FaceAlpha', 0.2, 'EdgeColor', 'y');
            end
            hold off;
            
            title(titleStr);
            ylabel('Firing Rate (Hz)');
            xlabel('Time (minutes)');
            grid on;
        end
    end

    % Save results
    if nargin > 3 && ~isempty(dataFolder) && ~isempty(sparseUnitsList)
        try
            timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
            saveDir = fullfile(dataFolder, 'sparseUnitTable');
            if ~exist(saveDir, 'dir')
                mkdir(saveDir);
            end
            
            tablePath = fullfile(saveDir, sprintf('sparseUnitsTable_%s.csv', timeStamp));
            writetable(sparseUnitsList, tablePath);
            
            figPath = fullfile(saveDir, sprintf('sparseUnits_plot_%s.fig', timeStamp));
            savefig(gcf, figPath);
            
            fprintf('Results saved to: %s\n', saveDir);
        catch ME
            fprintf('Error saving results:\n');
            fprintf('Message: %s\n', ME.message);
        end
    end
end
