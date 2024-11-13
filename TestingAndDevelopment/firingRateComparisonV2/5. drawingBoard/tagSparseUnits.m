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
    unitTable = table('Size', [numFields, 6], ...
                      'VariableTypes', {'string', 'string', 'string', ...
                                        'double', 'double', 'logical'}, ...
                      'VariableNames', {'unitID', 'recordingName', 'groupName', ...
                                        'peakFiringRate', 'silencePeriodRate', ...
                                        'isSingleFiring'});
    
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
                
                % Find peak firing period (adjust windows based on binWidth)
                minutesToSecs = 60;
                earlyWindowMins = 30; % 30 minutes for early window
                timeInMinutes = timeVector/minutesToSecs;
                
                earlyIdx = timeInMinutes <= earlyWindowMins;
                lateIdx = timeInMinutes > earlyWindowMins;
                
                if ~isempty(earlyIdx) && ~isempty(lateIdx)
                    % Calculate metrics
                    peakRate = max(psthData(earlyIdx));
                    silenceRate = mean(psthData(lateIdx));
                    peakTimeInMins = timeVector(find(psthData == peakRate, 1, 'first'))/minutesToSecs;
                    
                    % Define criteria for single firing pattern
                    hasSignificantPeak = peakRate > 0.4;  % Increased threshold to match example
                    hasLowLateFiring = silenceRate < 0.02; % Stricter silence criterion
                    peakToBaselineRatio = peakRate / (silenceRate + eps);
                    hasGoodContrast = peakToBaselineRatio > 15;
                    peakTimeCorrect = peakTimeInMins >= 5 && peakTimeInMins <= 20;
                    
                    % Combine criteria
                    isSingleFiring = hasSignificantPeak && hasLowLateFiring && ...
                                   hasGoodContrast && peakTimeCorrect;
                    
                    if isSingleFiring
                        fprintf('Found single-firing unit: %s\n', unitID);
                        fprintf('Peak rate: %.2f Hz at %.1f minutes\n', peakRate, peakTimeInMins);
                        fprintf('Silence rate: %.2f Hz\n', silenceRate);
                        fprintf('Peak-to-baseline ratio: %.1f\n\n', peakToBaselineRatio);
                    end
                    
                    % Store in table
                    unitTable.unitID(rowCounter) = string(unitID);
                    unitTable.recordingName(rowCounter) = string(recordingName);
                    unitTable.groupName(rowCounter) = string(groupName);
                    unitTable.peakFiringRate(rowCounter) = peakRate;
                    unitTable.silencePeriodRate(rowCounter) = silenceRate;
                    unitTable.isSingleFiring(rowCounter) = isSingleFiring;
                    
                    % Update unit structure with more detailed metrics
                    cellDataStruct.(groupName).(recordingName).(unitID).isSingleFiring = isSingleFiring;
                    cellDataStruct.(groupName).(recordingName).(unitID).firingMetrics = struct(...
                        'peakRate', peakRate, ...
                        'silenceRate', silenceRate, ...
                        'peakToSilenceRatio', peakToBaselineRatio, ...
                        'peakTime', timeVector(find(psthData == peakRate, 1, 'first')));
                    
                    rowCounter = rowCounter + 1;
                end
            end     
        end
    end

    % Trim any unused rows from the table
    unitTable = unitTable(1:rowCounter-1, :);

    % Create output table of single-firing units
    sparseUnitsList = unitTable(unitTable.isSingleFiring, :);
    
    % Sort by peak firing rate
    if ~isempty(sparseUnitsList)
        sparseUnitsList = sortrows(sparseUnitsList, 'peakFiringRate', 'descend');
        
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
            title(sprintf('Unit %s (Peak: %.2f Hz at %.1f mins)', ...
                  char(unitID), ...
                  cellDataStruct.(groupName).(recordingName).(unitID).firingMetrics.peakRate, ...
                  cellDataStruct.(groupName).(recordingName).(unitID).firingMetrics.peakTime/minutesToSecs));
            ylabel('Firing Rate (Hz)');
            xlabel('Time (minutes)');
            grid on;
            % Add vertical lines for analysis windows
            hold on;
            xline(30, '--r', 'Analysis cutoff');
            hold off;
        end
    end

    % Optional: save results
    if nargin > 4 && ~isempty(dataFolder) && ~isempty(sparseUnitsList)
        try
            timeStamp = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'));
            fileName = sprintf('sparseUnitsTable_%s.csv', timeStamp);
            
            saveDir = fullfile(dataFolder, 'sparseUnitTable');
            if ~exist(saveDir, 'dir')
                mkdir(saveDir);
            end
            
            savePath = fullfile(saveDir, fileName);
            writetable(sparseUnitsList, savePath);
            
            % Save figure if it was created
            if ~isempty(sparseUnitsList)
                figPath = fullfile(saveDir, sprintf('sparseUnits_plot_%s.fig', timeStamp));
                savefig(gcf, figPath);
                fprintf('Plot saved to: %s\n', figPath);
            end
            
            fprintf('Successfully saved results to: %s\n', savePath);
            
        catch ME
            fprintf('Error saving results:\n');
            fprintf('Message: %s\n', ME.message);
        end
    end
end





