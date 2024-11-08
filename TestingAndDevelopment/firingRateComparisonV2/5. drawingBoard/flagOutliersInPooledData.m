function [cellDataStruct, groupIQRs] = flagOutliersInPooledData(cellDataStruct, unitFilter, plotOutliers)
    % flagOutliersInPooledData: Identifies and flags extreme outlier units based on smoothed PSTHs.
    % Uses a strict IQR-based threshold with a k-factor of 3.0 for extreme outliers.

    % % Default input setup for debugging
    % if nargin < 3
    %     plotOutliers = true; % Enable plotting for debugging
    % end
    % if nargin < 2
    %     unitFilter = 'both'; % Include both single and multi-units
    % end
    % if nargin < 1
    %     % Load or initialize a sample cellDataStruct if not provided
    %     try
    %         load('C:\Users\adsil\Documents\Repos\SpikeTurnpikeClone\TestData\TestVariables\cellDataStruct.mat'); % Replace with your sample file path
    %         fprintf('Debug: Loaded default cellDataStruct from file.\n');
    %     catch
    %         error('cellDataStruct not provided and no default file found. Please provide a cellDataStruct.');
    %     end
    % end

    % Define response types and groups
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    experimentGroups = {'Emx', 'Pvalb'};

    % Initialize groupIQRs structure to store IQR and upper fence for each response type and group
    groupIQRs = struct();
    psthDataGroup = struct();
    unitInfoGroup = struct();

    % Set up empty structures for each response type and group
    for rType = responseTypes
        psthDataGroup.(rType{1}) = struct('Emx', [], 'Pvalb', []);
        unitInfoGroup.(rType{1}).Emx = {};   % Initialize as empty cell array for Emx
        unitInfoGroup.(rType{1}).Pvalb = {}; % Initialize as empty cell array for Pvalb
        groupIQRs.(rType{1}) = struct('Emx', struct('IQR', [], 'Median', [], 'UpperFence', [], 'LowerFence', []), ...
                                      'Pvalb', struct('IQR', [], 'Median', [], 'UpperFence', [], 'LowerFence', []));
    end

    % Loop through each experimental group and collect PSTH data
    fprintf('Debug: Starting data collection by group and response type\n');
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            fprintf('Warning: Group %s not found in cellDataStruct. Skipping.\n', groupName);
            continue;
        end
        
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Loop through each recording within the experimental group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            fprintf('Debug: Processing recording %s in group %s\n', recordingName, groupName);

            % Collect data for each unit within the recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                
                % Apply unit filter
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || ...
                   (strcmp(unitFilter, 'multi') && isSingleUnit)
                    fprintf('Debug: Skipping unit %s due to filter %s\n', unitID, unitFilter);
                    continue;
                end
                
                % Check if responseType exists; if not, issue a warning
                if isfield(unitData, 'responseType')
                    responseType = replace(unitData.responseType, ' ', ''); % Normalize 'No Change' to 'NoChange'
                else
                    fprintf('Warning: Unit %s in group %s, recording %s does not have a responseType field. Skipping.\n', unitID, groupName, recordingName);
                    continue; % Skip this unit if responseType is missing
                end
                
                fprintf('Debug: Processing unit %s with response type %s\n', unitID, responseType);
                
                % Store PSTH data and unit info at the group level
                if isfield(unitData, 'psthSmoothed')
                    maxFiringRate = max(unitData.psthSmoothed);
                    psthDataGroup.(responseType).(groupName) = [psthDataGroup.(responseType).(groupName); maxFiringRate];
                    unitInfoGroup.(responseType).(groupName){end+1} = struct('group', groupName, 'recording', recordingName, 'id', unitID);
                    fprintf('Debug: Added max firing rate %f for unit %s in group %s, response type %s\n', maxFiringRate, unitID, groupName, responseType);
                else
                    fprintf('Warning: Unit %s does not have psthSmoothed data\n', unitID);
                end
            end
        end
    end

    % Calculate IQR, median, and thresholds for each response type and group
    fprintf('Debug: Calculating IQR and thresholds for each response type and group\n');
    for rType = responseTypes
        for grp = experimentGroups
            maxRatesGroup = psthDataGroup.(rType{1}).(grp{1});
            fprintf('Debug: Calculating for response type %s, group %s\n', rType{1}, grp{1});
            if ~isempty(maxRatesGroup)
                Q1 = prctile(maxRatesGroup, 25);
                Q3 = prctile(maxRatesGroup, 75);
                IQR_value = Q3 - Q1;
                upperFence = Q3 + 1.5 * IQR_value;
                lowerFence = Q1 - 1.5 * IQR_value;

                % Store IQR information in groupIQRs
                groupIQRs.(rType{1}).(grp{1}).IQR = IQR_value;
                groupIQRs.(rType{1}).(grp{1}).Median = median(maxRatesGroup);
                groupIQRs.(rType{1}).(grp{1}).UpperFence = upperFence;
                groupIQRs.(rType{1}).(grp{1}).LowerFence = lowerFence;
                fprintf('Debug: Calculated IQR=%f, Median=%f, UpperFence=%f, LowerFence=%f\n', IQR_value, median(maxRatesGroup), upperFence, lowerFence);
            else
                fprintf('Warning: No max rates found for response type %s in group %s\n', rType{1}, grp{1});
            end
        end
    end

    % Flag outliers in cellDataStruct based on strict IQR threshold
    fprintf('Debug: Flagging outliers based on IQR thresholds\n');
    for rType = responseTypes
        for grp = experimentGroups
            fprintf('Debug: Checking outliers for response type %s, group %s\n', rType{1}, grp{1});
            for i = 1:length(unitInfoGroup.(rType{1}).(grp{1}))
                unitInfo = unitInfoGroup.(rType{1}).(grp{1}){i};
                maxFiringRate = psthDataGroup.(rType{1}).(grp{1})(i);
                
                if maxFiringRate > groupIQRs.(rType{1}).(grp{1}).UpperFence || maxFiringRate < groupIQRs.(rType{1}).(grp{1}).LowerFence
                    cellDataStruct.(unitInfo.group).(unitInfo.recording).(unitInfo.id).isOutlierExperimental = true;
                    fprintf('Debug: Flagged unit %s as outlier with max firing rate %f\n', unitInfo.id, maxFiringRate);
                else
                    fprintf('Debug: Unit %s is not an outlier (max firing rate %f)\n', unitInfo.id, maxFiringRate);
                end
            end
        end
    end

    % Optional: Plotting function if specified
    if plotOutliers
        plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs);
    end
end

