function cellDataStruct = calculateGroupAveragePSTHAndSEM(cellDataStruct, dataFolder)
    % calculateGroupAveragePSTHAndSEM: Computes average and SEM of PSTHs for each group based on recording-level data.
    % Adds the group-level mean and SEM PSTH under 'groupData' at the group level in cellDataStruct.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing recording-level average and SEM PSTH data.
    %   - dataFolder: Directory where the updated cellDataStruct will be saved.
    %
    % Outputs:
    %   - cellDataStruct: Updated structure with mean and SEM PSTH stored under 'groupData' for each group.

    % Verify the data folder path
    if nargin < 2 || isempty(dataFolder)
        error('Please specify a valid dataFolder path for saving the cellDataStruct.');
    end

    % Set full path for saving the struct
    cellDataStructPath = fullfile(dataFolder, 'cellDataStruct.mat');

    % Loop through each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        fprintf('Processing Group: %s\n', groupName);

        recordings = fieldnames(cellDataStruct.(groupName));

        % Initialize arrays to accumulate recording-level averages and SEMs
        groupPSTHs = [];
        groupSEMs = [];

        for r = 1:length(recordings)
            recordingName = recordings{r};

            % Retrieve recording-level avgPSTH and semPSTH
            recordingData = cellDataStruct.(groupName).(recordingName).recordingData;
            avgPSTH = recordingData.avgPSTH;
            semPSTH = recordingData.semPSTH;

            % Accumulate data for group-level calculations
            groupPSTHs = [groupPSTHs; avgPSTH];
            groupSEMs = [groupSEMs; semPSTH];
        end

        % Calculate group-level mean and SEM
        groupAvgPSTH = mean(groupPSTHs, 1, 'omitnan');
        groupSEM = sqrt(sum(groupSEMs.^2, 1, 'omitnan')) / size(groupSEMs, 1);

        % Store group-level average and SEM in the struct under 'groupData'
        cellDataStruct.(groupName).groupData.avgPSTH = groupAvgPSTH;
        cellDataStruct.(groupName).groupData.semPSTH = groupSEM;
        fprintf('Calculated group avgPSTH and semPSTH for Group: %s\n', groupName);
    end

    % Save updated struct
    try
        save(cellDataStructPath, 'cellDataStruct', '-v7.3');
        fprintf('Saved cellDataStruct to: %s\n', cellDataStructPath);

        if ~isfile(cellDataStructPath)
            error('SaveError:VerificationFailed', 'Failed to verify the saved file: %s', cellDataStructPath);
        end

    catch ME
        fprintf('Error occurred during saving: %s\n', ME.message);
        rethrow(ME);
    end
end
