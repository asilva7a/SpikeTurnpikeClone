%% Function to Label Responsive Units. Takes all_data as input and returns a cell array of unit names categorized by response type.
%% Inputs:
% - all_data: A struct containing firing rate data for all units
%% Outputs:
% - cidArray: A 2D cell array containing unit names categorized by response type


function cidArray = labelResponsiveUnits_fun(all_data)
    % Initialize cell array to store response types
    responseTypeVec = cell(length(FRs_before), 1);
    
%% Perform Bootstrapping to Identify Significant Changes
    nBootstraps = 1000;  % Number of bootstrap iterations
    alpha = 0.05;  % Significance level for 95% confidence intervals (CIs)

    % Pre-allocate arrays to store CI results
    lower_CI = nan(length(FRs_before), 1);  % Lower bound of CI
    upper_CI = nan(length(FRs_before), 1);  % Upper bound of CI

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

    % Function to categorize units by their response type
    function cidArray = categorize_units_by_response(all_data)
    % Initialize cell arrays for each category
    positiveCIDs = {};
    negativeCIDs = {};
    nonResponsiveCIDs = {};

    % Iterate over all groups, recordings, and units
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            for u = 1:length(unitNames)
                unitName = unitNames{u};
                unitData = all_data.(groupName).(recordingName).(unitName);

                % Classify units based on ResponseType
                if strcmp(unitData.ResponseType, 'Increased')
                    positiveCIDs{end+1} = unitName;
                elseif strcmp(unitData.ResponseType, 'Decreased')
                    negativeCIDs{end+1} = unitName;
                else
                    nonResponsiveCIDs{end+1} = unitName;
                end
            end
        end
    end

    % Store the lists in a 2D cell array
    cidArray = {positiveCIDs; negativeCIDs; nonResponsiveCIDs};
    end

    % Example usage: Call the function and access specific categories
    cidArray = categorize_units_by_response(all_data);

    % Access positive, negative, and non-responsive units
    positiveUnits = cidArray{1};
    negativeUnits = cidArray{2};
    nonResponsiveUnits = cidArray{3};

