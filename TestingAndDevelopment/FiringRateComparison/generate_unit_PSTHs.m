% Define analysis parameters
binSize = 0.1;  % 100ms bins for PSTH
smoothingWindow = [1 1 1 1 1];  % Light smoothing window
moment = 1860;  % Reference event (e.g., stimulus onset)
preTreatmentPeriod = 1800;  % Seconds before the event
postTreatmentPeriod = 1800;  % Seconds after the event


function generate_PSTHs(data_table_FR, all_data, binSize, smoothingWindow, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Define colors for responsivity types
    colors = struct('Increased', [1, 0, 0], ...  % Red
                    'Decreased', [0, 0, 1], ...  % Blue
                    'NoChange', [0, 0, 0]);      % Black

    % Get group names from the data table
    uniqueGroups = unique(data_table_FR.Group);

    % Iterate over all unique recording groups
    for g = 1:length(uniqueGroups)
        groupName = uniqueGroups{g};
        
        % Filter the data table for the current group
        groupTable = data_table_FR(strcmp(data_table_FR.Group, groupName), :);

        % Create a new figure for the current group
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');

        % Create subplots: one for each response type
        responseTypes = {'Increased', 'Decreased', 'No Change'};
        for rt = 1:length(responseTypes)
            subplot(1, 3, rt);  % Create 3 subplots: one per response type
            hold on;
            title([groupName, ' - ', responseTypes{rt}]);
            xlabel('Time Bin');
            ylabel('Firing Rate (Hz)');

            % Filter the group table for the current response type
            responseTable = groupTable(strcmp(groupTable.ResponseType, responseTypes{rt}), :);

            % Plot each unit's PSTH in the appropriate subplot
            for u = 1:height(responseTable)
                unitID = responseTable.UnitID{u};
                recordingName = find_recording_for_unit(all_data, groupName, unitID);
                
                if isempty(recordingName)
                    warning('Unit %s not found in all_data. Skipping.', unitID);
                    continue;
                end
                
                % Extract the spike times for this unit
                spikeTimes = all_data.(groupName).(recordingName).(unitID).SpikeTimes_all / ...
                             all_data.(groupName).(recordingName).(unitID).Sampling_Frequency;
                
                % Calculate and smooth the PSTH
                psthCounts = histcounts(spikeTimes, ...
                    moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod);
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');
                
                % Plot the PSTH
                plot(smoothedPSTH, 'Color', colors.(strrep(responseTypes{rt}, ' ', '')), 'LineWidth', 1.5);
            end
            hold off;
        end
    end
end

% Helper function to find the recording name for a given unit
function recordingName = find_recording_for_unit(all_data, groupName, unitID)
    % Iterate through all recordings in the group to find the unit
    recordingNames = fieldnames(all_data.(groupName));
    for r = 1:length(recordingNames)
        if isfield(all_data.(groupName).(recordingNames{r}), unitID)
            recordingName = recordingNames{r};
            return;
        end
    end
    recordingName = '';  % Return empty if unit not found
end

