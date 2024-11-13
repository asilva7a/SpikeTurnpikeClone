function [cellDataStruct, sparseUnitsList] = tagSparseUnits(cellDataStruct, frBefore, binWidth, minFrRate, dataFolder)
    % tagSparseUnits Tags units with specific firing patterns
    % Inputs:
    %   cellDataStruct: Nested structure containing unit data
    %   frBefore: Firing rates before treatment
    %   binWidth: Width of time bins in seconds
    %   minFrRate: Minimum firing rate threshold (default 0.5 Hz)
    %   dataFolder: Optional path for saving results
    % Outputs:
    %   cellDataStruct: Updated structure with tagged units
    %   sparseUnitsList: Table containing identified units
    
    % Set default args
    if nargin < 4 || isempty(minFrRate)
        minFrRate = 0.5; % set min fr rate to 0.5Hz
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
    
    % Initiate data table
    unitTable = table('Size', [numFields, 9], ...
                      'VariableTypes', {'string', 'string', 'string', ...
                                        'double', 'double', 'logical', ...
                                        'logical', 'double', 'double'}, ...
                      'VariableNames', {'unitID', 'recordingName', 'groupName', ...
                                        'peakFiringRate', 'silencePeriodRate', ...
                                        'isSingleFiring', 'hasSquareWave', ...
                                        'squareWaveStartTime', 'squareWaveDuration'});
    
    % Initialize counter for table rows
    rowCounter = 1;

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
                minutesToSecs = 60;
                timeInMinutes = timeVector/minutesToSecs;
                
                % Define time windows for analysis
                earlyWindowMins = 30;
                earlyIdx = timeInMinutes <= earlyWindowMins;
                lateIdx = timeInMinutes > earlyWindowMins;
                
                % Now we can safely calculate metrics
                if ~isempty(earlyIdx) && ~isempty(lateIdx)
                    % Single firing metrics
                    peakRate = max(psthData(earlyIdx));
                    silenceRate = mean(psthData(lateIdx));
                    peakTimeInMins = timeVector(find(psthData == peakRate, 1, 'first'))/minutesToSecs;
                    
                    % Calculate rate of decline after peak
                    peakIndex = find(psthData == peakRate, 1, 'first');
                    if peakIndex < length(psthData)-5  % Ensure enough points after peak
                        % Calculate average rate of decline over next 5 minutes
                        postPeakWindow = peakIndex:(peakIndex + round(5 * 60/binWidth));
                        postPeakWindow = postPeakWindow(postPeakWindow <= length(psthData));
                        rateOfDecline = abs(diff(psthData(postPeakWindow(1:min(end,10))))/binWidth);
                        isAbruptDecline = mean(rateOfDecline) > 0.1; % Threshold for abrupt decline
                    else
                        isAbruptDecline = false;
                    end
                    
                    % Modified single firing criteria
                    hasSignificantPeak = peakRate > 0.3;
                    hasLowLateFiring = silenceRate < 0.05;  % Stricter silence requirement
                    peakToBaselineRatio = peakRate / (silenceRate + eps);
                    hasGoodContrast = peakToBaselineRatio > 8;
                    peakTimeCorrect = peakTimeInMins <= 20;
                    
                    % Combine criteria - must have abrupt decline
                    isSingleFiring = hasSignificantPeak && hasLowLateFiring && ...
                                     hasGoodContrast && peakTimeCorrect && isAbruptDecline;
                                        
                    % Square wave detection
                    windowSize = 5; % minutes
                    stepSize = 1;   % minutes
                    minSquareDuration = 2; % minutes
                    hasSquareWave = false;
                    squareMetrics = struct('startTime', 0, 'duration', 0, 'amplitude', 0);
                    
                    % Convert time windows to indices
                    pointsPerMin = sum(timeInMinutes <= 1);
                    windowPoints = round(windowSize * pointsPerMin);
                    stepPoints = round(stepSize * pointsPerMin);
                    
                    % Scan through recording
                    for startIdx = 1:stepPoints:length(psthData)-windowPoints
                        endIdx = startIdx + windowPoints - 1;
                        windowData = psthData(startIdx:endIdx);
                        windowTime = timeInMinutes(startIdx:endIdx);
                        
                        % Calculate metrics
                        meanRate = mean(windowData);
                        cv = std(windowData)/meanRate;
                        
                        % Check for square wave characteristics
                        if meanRate > 0.2 && cv < 0.25 % Stable firing above threshold
                            % Check edges
                            if startIdx > 1 && endIdx < length(psthData)
                                beforeRate = mean(psthData(max(1,startIdx-3):startIdx-1));
                                afterRate = mean(psthData(endIdx+1:min(length(psthData),endIdx+3)));
                                
                                % Calculate transition sharpness
                                onsetRatio = meanRate/max(beforeRate, eps);
                                offsetRatio = meanRate/max(afterRate, eps);
                                
                                if onsetRatio > 3 && offsetRatio > 3 && ...
                                   (windowTime(end)-windowTime(1)) >= minSquareDuration
                                    hasSquareWave = true;
                                    squareMetrics.startTime = windowTime(1);
                                    squareMetrics.duration = windowTime(end)-windowTime(1);
                                    squareMetrics.amplitude = meanRate;
                                    break
                                end
                            end
                        end
                    end
                    
                    % Store results in table
                    unitTable.unitID(rowCounter) = string(unitID);
                    unitTable.recordingName(rowCounter) = string(recordingName);
                    unitTable.groupName(rowCounter) = string(groupName);
                    unitTable.peakFiringRate(rowCounter) = peakRate;
                    unitTable.silencePeriodRate(rowCounter) = silenceRate;
                    unitTable.isSingleFiring(rowCounter) = isSingleFiring;
                    unitTable.hasSquareWave(rowCounter) = hasSquareWave;
                    unitTable.squareWaveStartTime(rowCounter) = squareMetrics.startTime;
                    unitTable.squareWaveDuration(rowCounter) = squareMetrics.duration;
                    
                    % Update unit structure
                    cellDataStruct.(groupName).(recordingName).(unitID).isSingleFiring = isSingleFiring;
                    cellDataStruct.(groupName).(recordingName).(unitID).hasSquareWave = hasSquareWave;
                    
                    if isSingleFiring
                        cellDataStruct.(groupName).(recordingName).(unitID).firingMetrics = struct(...
                            'peakRate', peakRate, ...
                            'silenceRate', silenceRate, ...
                            'peakToSilenceRatio', peakToBaselineRatio, ...
                            'peakTime', timeVector(find(psthData == peakRate, 1, 'first')));
                            
                        fprintf('Found single-firing unit: %s\n', unitID);
                        fprintf('Peak rate: %.2f Hz at %.1f minutes\n', peakRate, peakTimeInMins);
                        fprintf('Silence rate: %.2f Hz\n\n', silenceRate);
                    end
                    
                    if hasSquareWave
                        cellDataStruct.(groupName).(recordingName).(unitID).squareMetrics = squareMetrics;
                        
                        fprintf('Found square wave in unit: %s\n', unitID);
                        fprintf('Time: %.1f-%.1f minutes\n', squareMetrics.startTime, ...
                            squareMetrics.startTime + squareMetrics.duration);
                        fprintf('Amplitude: %.2f Hz\n\n', squareMetrics.amplitude);
                    end
                    
                    rowCounter = rowCounter + 1;
                end
            end     
        end
    end

    % Trim any unused rows from the table
    unitTable = unitTable(1:rowCounter-1, :);

    % Create output table of identified units
    sparseUnitsList = unitTable(unitTable.isSingleFiring | unitTable.hasSquareWave, :);
    
    % Sort by pattern type
    if ~isempty(sparseUnitsList)
        sparseUnitsList = sortrows(sparseUnitsList, {'isSingleFiring', 'hasSquareWave'}, {'descend', 'descend'});
        
        % Create visualization
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
            
            if sparseUnitsList.hasSquareWave(i)
                squareMetrics = cellDataStruct.(groupName).(recordingName).(unitID).squareMetrics;
                titleStr = sprintf('Unit %s (Square wave: %.2f Hz, %.1f-%.1f min)', ...
                    char(unitID), squareMetrics.amplitude, ...
                    squareMetrics.startTime, squareMetrics.startTime + squareMetrics.duration);
                
                % Highlight square wave period
                hold on;
                ylims = ylim;
                patch([squareMetrics.startTime, squareMetrics.startTime + squareMetrics.duration, ...
                       squareMetrics.startTime + squareMetrics.duration, squareMetrics.startTime], ...
                      [ylims(1) ylims(1) ylims(2) ylims(2)], ...
                      'y', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
                hold off;
            else
                titleStr = sprintf('Unit %s (Single firing: Peak %.2f Hz at %.1f min)', ...
                    char(unitID), ...
                    cellDataStruct.(groupName).(recordingName).(unitID).firingMetrics.peakRate, ...
                    cellDataStruct.(groupName).(recordingName).(unitID).firingMetrics.peakTime/minutesToSecs);
            end
            
            title(titleStr);
            ylabel('Firing Rate (Hz)');
            xlabel('Time (minutes)');
            grid on;
        end
    end

    % Save results
    if nargin > 4 && ~isempty(dataFolder) && ~isempty(sparseUnitsList)
        try
            timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
            saveDir = fullfile(dataFolder, 'sparseUnitTable');
            if ~exist(saveDir, 'dir')
                mkdir(saveDir);
            end
            
            % Save table
            tablePath = fullfile(saveDir, sprintf('sparseUnitsTable_%s.csv', timeStamp));
            writetable(sparseUnitsList, tablePath);
            
            % Save figure
            figPath = fullfile(saveDir, sprintf('sparseUnits_plot_%s.fig', timeStamp));
            savefig(gcf, figPath);
            
            fprintf('Results saved to: %s\n', saveDir);
            
        catch ME
            fprintf('Error saving results:\n');
            fprintf('Message: %s\n', ME.message);
        end
    end
end
