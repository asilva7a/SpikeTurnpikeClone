function [cellDataStruct, calculatedUnits] = calculateTimeSeriesChange(cellDataStruct, treatmentTime, baselineWindow)
    % calculateTimeSeriesPercentChange: Computes percent change for each bin relative to a baseline
    % period median for each unit and saves it in the cellDataStruct.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing group, recording, and unit data.
    %   - treatmentTime: Time in seconds when treatment was administered.
    %   - baselineWindow: Duration in seconds before the treatmentTime to use for baseline calculation.
    %
    % Outputs:
    %   - cellDataStruct: Updated structure with percent change time series and metadata saved for each unit.
    %   - calculatedUnits: Cell array of strings listing units for which percent change was calculated.

    if nargin < 2 || isempty(treatmentTime)
        treatmentTime = 1860; % Default treatment time in seconds
    end
    if nargin < 3 || isempty(baselineWindow)
        baselineWindow = 300; % Default baseline window in seconds
    end

    calculatedUnits = {};  % Initialize list of units where percent change was calculated

    % Loop through each group, recording, and unit
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Check for required fields
                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'binEdges')
                    try
                        % Extract the PSTH data and time vector
                        psth = unitData.psthSmoothed;
                        binEdges = unitData.binEdges;
                        binWidth = binEdges(2) - binEdges(1); % Bin width in seconds
                        timeVector = binEdges(1:end-1) + binWidth / 2; % Bin centers

                        % Identify baseline period indices
                        baselineIndices = (timeVector >= (treatmentTime - baselineWindow)) & (timeVector < treatmentTime);
                        baselineMedian = median(psth(baselineIndices), 'omitnan');

                        % Calculate percent change relative to baseline median
                        if baselineMedian == 0
                            warning('Baseline median is zero for Unit %s. Percent change set to NaN.', unitID);
                            percentChangeSeries = NaN(size(psth));
                        else
                            percentChangeSeries = ((psth - baselineMedian) / abs(baselineMedian)) * 100;
                        end

                        % Calculate metadata for percent change time series
                        percentChangeStats = struct();
                        percentChangeStats.meanChange = mean(percentChangeSeries, 'omitnan');
                        percentChangeStats.medianChange = median(percentChangeSeries, 'omitnan');
                        percentChangeStats.stdChange = std(percentChangeSeries, 'omitnan');
                        percentChangeStats.varChange = var(percentChangeSeries, 'omitnan');
                        percentChangeStats.maxChange = max(percentChangeSeries, [], 'omitnan');
                        percentChangeStats.minChange = min(percentChangeSeries, [], 'omitnan');
                        percentChangeStats.changeType = 'Percent Change';

                        % Save the percent change time series and stats in the struct
                        cellDataStruct.(groupName).(recordingName).(unitID).percentChangeTimeSeries = percentChangeSeries;
                        cellDataStruct.(groupName).(recordingName).(unitID).percentChangeStats = percentChangeStats;

                        % Add unit to the calculated list
                        calculatedUnits{end+1} = sprintf('%s - %s - %s', groupName, recordingName, unitID);

                        % Display confirmation message
                        fprintf('Calculated percent change time series and stats for Unit %s in %s - %s.\n', ...
                            unitID, groupName, recordingName);

                    catch ME
                        % Handle errors and provide detailed error message
                        errorMsg = sprintf('Error calculating percent change for Unit %s in %s - %s: %s\n', ...
                                            unitID, groupName, recordingName, ME.message);
                        for k = 1:length(ME.stack)
                            errorMsg = sprintf('%s In %s (line %d)\n', errorMsg, ME.stack(k).file, ME.stack(k).line);
                        end
                        warning(errorMsg);
                    end
                else
                    warning('Skipping Unit %s in %s - %s: Missing required fields.', unitID, groupName, recordingName);
                end
            end
        end
    end

    % Display list of calculated units
    fprintf('\nUnits with percent change calculated:\n');
    fprintf('%s\n', calculatedUnits{:});
end
