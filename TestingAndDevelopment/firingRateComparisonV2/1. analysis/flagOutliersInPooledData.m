function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers, dataFolder)
    % flagOutliersInPooledData: Identifies and flags extreme outlier units based on smoothed PSTHs.
    % All units will have an isOutlierExperimental field where 1 indicates an outlier and 0 indicates non-outlier.

    % Define response types and groups
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    experimentGroups = {'Emx', 'Pvalb', 'Control'};
    
    % Initialize groupIQRs structure to store IQR and upper fence for each response type and group
    groupIQRs = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();

    % Set up empty structures for each response type and group
    for rType = responseTypes
        psthDataGroup.(rType{1}) = struct('Emx', [], 'Pvalb', [], 'Control', []);
        unitInfoGroup.(rType{1}).Emx = {};
        unitInfoGroup.(rType{1}).Pvalb = {};
        unitInfoGroup.(rType{1}).Control = {};
        groupIQRs.(rType{1}) = struct( ...
            'Emx', struct('IQR', [], 'Median', [], 'UpperFence', [], 'LowerFence', []), ...
            'Pvalb', struct('IQR', [], 'Median', [], 'UpperFence', [], 'LowerFence', []), ...
            'Control', struct('IQR', [], 'Median', [], 'UpperFence', [], 'LowerFence', []) ...
        );
    end

    % Loop through each experimental group and collect PSTH data
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Loop through each recording within the recording group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            % Collect data for each unit within the recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                % Inside the loop for each unit

                % Display the unit being processed for debugging
                fprintf('Processing Group: %s | Recording: %s | Unit: %s\n', ...
                        groupName, recordingName, unitID);

                % Initialize isOutlierExperimental field with a default value of 0
                cellDataStruct.(groupName).(recordingName).(unitID).isOutlierExperimental = 0;
                
                % Apply unit filter
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue;
                end
                
                if isfield(unitData, 'responseType')
                    % Convert responseType to string/char if it isn't already
                    if ischar(unitData.responseType)
                        responseType = strrep(unitData.responseType, ' ', '');
                    elseif isstring(unitData.responseType)
                        responseType = replace(unitData.responseType, ' ', '');
                    else
                        responseType = char(unitData.responseType);
                        responseType = strrep(responseType, ' ', '');
                    end
                    
                    % Skip 'Mostly Silent' and 'Mostly Zeroes' units
                    if strcmp(responseType, 'MostlySilent') || strcmp(responseType, 'MostlyZero')
                        continue;
                    end
                else
                    continue; % Skip this unit if responseType is missing
                end
                
                % Store PSTH data and unit info at the group level
                if isfield(unitData, 'psthSmoothed')
                    maxFiringRate = max(unitData.psthSmoothed);
                    psthDataGroup.(responseType).(groupName) = [psthDataGroup.(responseType).(groupName); maxFiringRate];
                    unitInfoGroup.(responseType).(groupName){end+1} = struct('group', groupName, 'recording', recordingName, 'id', unitID);
                end
            end
        end
    end

    % Calculate IQR, median, and thresholds for each response type and group
    for rType = responseTypes
        for grp = experimentGroups
            maxRatesGroup = psthDataGroup.(rType{1}).(grp{1});
            if ~isempty(maxRatesGroup)
                Q1 = prctile(maxRatesGroup, 25);
                Q3 = prctile(maxRatesGroup, 75);
                IQR_value = Q3 - Q1;
                upperFence = Q3 + 3.0 * IQR_value;
                lowerFence = Q1 - 3.0 * IQR_value;

                % Store IQR information in groupIQRs
                groupIQRs.(rType{1}).(grp{1}).IQR = IQR_value;
                groupIQRs.(rType{1}).(grp{1}).Median = median(maxRatesGroup);
                groupIQRs.(rType{1}).(grp{1}).UpperFence = upperFence;
                groupIQRs.(rType{1}).(grp{1}).LowerFence = lowerFence;
            end
        end
    end

    % Flag outliers in cellDataStruct based on strict IQR threshold
    for rType = responseTypes
        for grp = experimentGroups
            for i = 1:length(unitInfoGroup.(rType{1}).(grp{1}))
                unitInfo = unitInfoGroup.(rType{1}).(grp{1}){i};
                maxFiringRate = psthDataGroup.(rType{1}).(grp{1})(i);
                
                % Flag as outlier if max firing rate exceeds upper or lower fence
                if maxFiringRate > groupIQRs.(rType{1}).(grp{1}).UpperFence || maxFiringRate < groupIQRs.(rType{1}).(grp{1}).LowerFence
                    cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = 1;
                end
            end
        end
    end
    
    % Save the updated struct to the specified data file path
        try
            save(dataFolder, 'cellDataStruct', '-v7');
            fprintf('Struct saved successfully to: %s\n', dataFolder);
        catch ME
            fprintf('Error saving the file: %s\n', ME.message);
        end  
end


