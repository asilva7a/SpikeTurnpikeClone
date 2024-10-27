function psthData = generate_unit_PSTHs(data_table_FR, all_data, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % This function generates PSTHs for each unit in the provided data and
    % stores them in a structured output for future plotting.
    
    % Initialize storage structure for PSTHs
    psthData = struct();

    % Get unique group names from the data table
    uniqueGroups = unique(data_table_FR.Group);

    % Iterate over all unique recording groups
    for g = 1:length(uniqueGroups)
        groupName = uniqueGroups{g};
        
        % Filter the data table for the current group
        groupTable = data_table_FR(strcmp(data_table_FR.Group, groupName), :);

        % Initialize group field in the output structure
        psthData.(groupName) = struct();

        % Define response types
        responseTypes = {'Increased', 'Decreased', 'No Change'};
        
        % Iterate over response types
        for rt = 1:length(responseTypes)
            responseType = responseTypes{rt};
            
            % Filter the table for the current response type
            responseTable = groupTable(strcmp(groupTable.ResponseType, responseType), :);

            % Iterate over each unit in the filtered table
            for u = 1:height(responseTable)
                unitID = responseTable.UnitID{u};
                
                % Find the recording name for this unit
                recordingName = find_recording_for_unit(all_data, groupName, unitID);

                % If the recording is not found, skip this unit
                if isempty(recordingName)
                    warning('Unit %s not found in all_data. Skipping.', unitID);
                    continue;
                end

                % Extract spike times for this unit
                spikeTimes = all_data.(groupName).(recordingName).(unitID).SpikeTimes_all / ...
                             all_data.(groupName).(recordingName).(unitID).Sampling_Frequency;

                % Calculate the PSTH
                binEdges = moment - preTreatmentPeriod : binSize : moment + postTreatmentPeriod;
                psthCounts = histcounts(spikeTimes, binEdges);

                % Store the PSTH data in the structure
                psthData.(groupName).(unitID).PSTH = psthCounts;
                psthData.(groupName).(unitID).ResponseType = responseType;
                psthData.(groupName).(unitID).BinEdges = binEdges;
            end
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
