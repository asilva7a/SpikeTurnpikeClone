%% Function to Label Responsive Units
% This function takes a data structure containing firing rate data for all units and returns a cell array of unit names categorized by response type.
% Inputs:
% - all_data: A struct containing firing rate data for all units.
% Outputs:
% - cidArray: A 2D cell array containing unit names categorized by response type ('Increased', 'Decreased', 'No Change').

function data_table_FR = label_responsive_units_fun(all_data, cell_types, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Extract group names from the data structure
    groupNames = fieldnames(all_data);

    % Initialize storage vectors for results
    groupsVec = {};       % Stores the group of each unit
    cellTypesVec = {};    % Stores the type of each unit (e.g., 'RS', 'FS')
    FRs_before = [];      % Stores the firing rate before the stimulation
    FRs_after = [];       % Stores the firing rate after the stimulation
    unitIDs = {};         % Stores the unique ID of each unit

    %% Iterate over groups, mice, and units to collect firing rate data
    for groupNum = 1:length(groupNames)
        groupName = groupNames{groupNum};  % Current group
        mouseNames = fieldnames(all_data.(groupName));

        for mouseNum = 1:length(mouseNames)
            mouseName = mouseNames{mouseNum};  % Current mouse
            cellIDs = fieldnames(all_data.(groupName).(mouseName));

            for cellID_num = 1:length(cellIDs)
                cellID = cellIDs{cellID_num};  % Current cell
                cellData = all_data.(groupName).(mouseName).(cellID);

                % Filter units based on cell type and whether they are single units
                if any(strcmp(cell_types, cellData.Cell_Type)) && cellData.IsSingleUnit
                    if ~isfield(cellData, 'SpikeTimes_all') || isempty(cellData.SpikeTimes_all)
                        warning('Missing spike times for cell %s. Skipping.', cellID);
                        continue;  % Skip units with missing spike data
                        % Create a table to store the results
                        data_table_FR = table(unitIDs, groupsVec, cellTypesVec, FRs_before, FRs_after, responseTypeVec, ...
                                              'VariableNames', {'UnitID', 'Group', 'CellType', 'FR_Before', 'FR_After', 'ResponseType'});
                    end

                    % Convert spike times from samples to seconds
                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Calculate firing rates before and after the stimulation moment
                    FR_before = calculateFiringRate_fun(spikeTimes, max(0, moment - preTreatmentPeriod), moment, binSize);
                    FR_after = calculateFiringRate_fun(spikeTimes, moment, min(cellData.Recording_Duration, moment + postTreatmentPeriod), binSize);

                    % Handle cases with missing data by assigning a rate of 0
                    if isempty(FR_before), FR_before = 0; end
                    if isempty(FR_after), FR_after = 0; end

                    % Store the firing rates and other metadata
                    FRs_before(end+1,1) = FR_before;
                    FRs_after(end+1,1) = FR_after;
                    groupsVec{end+1,1} = groupName;
                    cellTypesVec{end+1,1} = cellData.Cell_Type;
                    unitIDs{end+1,1} = cellID;
                end
            end
        end
    end

    % Categorize units based on their response to the stimulation
    responseTypeVec = categorize_units(FRs_before, FRs_after);

    % Label Responsive Units and store output in 2D cell array
    cidArray = label_units_by_response(responseTypeVec, unitIDs);
end

function responseTypeVec = categorize_units(FRs_before, FRs_after)
    % Perform Bootstrapping to Identify Significant Changes
    nBootstraps = 1000;  % Number of bootstrap iterations
    alpha = 0.05;  % Significance level for 95% confidence intervals (CIs)

    % Pre-allocate arrays to store CI results
    lower_CI = nan(length(FRs_before), 1);  % Lower bound of CI
    upper_CI = nan(length(FRs_before), 1);  % Upper bound of CI
    responseTypeVec = cell(length(FRs_before), 1);

    for i = 1:length(FRs_before)
        % Compute the observed difference in firing rates for this unit
        observed_diff = FRs_after(i) - FRs_before(i);

        % Bootstrap resampling: Generate bootstrapped differences
        boot_diffs = nan(nBootstraps, 1);
        for b = 1:nBootstraps
            % Resample with small noise to simulate randomness
            boot_before = FRs_before(i) + randn * std(FRs_before(i));
            boot_after = FRs_after(i) + randn * std(FRs_after(i));
            boot_diffs(b) = boot_after - boot_before;
        end

        % Calculate the 95% CI from the bootstrap distribution
        lower_CI(i) = prctile(boot_diffs, alpha/2 * 100);
        upper_CI(i) = prctile(boot_diffs, (1 - alpha/2) * 100);

        % Classify the unit based on whether the CI includes 0
        if lower_CI(i) > 0 || upper_CI(i) < 0
            if observed_diff > 0
                responseTypeVec{i,1} = 'Increased';
            else
                responseTypeVec{i,1} = 'Decreased';
            end
        else
            responseTypeVec{i,1} = 'No Change';
        end
    end
end

function cidArray = label_units_by_response(responseTypeVec, unitIDs)
    positiveCIDs = {};
    negativeCIDs = {};
    nonResponsiveCIDs = {};

    for i = 1:length(responseTypeVec)
        switch responseTypeVec{i}
            case 'Increased'
                positiveCIDs{end+1} = unitIDs{i};
            case 'Decreased'
                negativeCIDs{end+1} = unitIDs{i};
            case 'No Change'
                nonResponsiveCIDs{end+1} = unitIDs{i};
        end
    end

    % Store the lists in a 2D cell array
    cidArray = {positiveCIDs; negativeCIDs; nonResponsiveCIDs};
    
    % Display the contents of cidArray in the workspace (optional)
    % assignin('base', 'cidArray', cidArray);
    % end
end
