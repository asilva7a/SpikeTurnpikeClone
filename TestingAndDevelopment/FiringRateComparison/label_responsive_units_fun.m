%% Function to Label Responsive Units
% This function takes a data structure containing firing rate data for all units and returns a cell array of unit names categorized by response type.
% Inputs:
% - all_data: A struct containing firing rate data for all units.
% Outputs:
% - cidArray: A 2D cell array containing unit names categorized by response type ('Increased', 'Decreased', 'No Change').

function data_table_FR = label_responsive_units_fun(all_data, cell_types, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    %Gaussian filter for temporal smoothing
    gausssigma = 1; %standard deviation of the gaussian filter
    gausswindow = 5; %width of the gaussian filter in standard deviations
    tempfilter = exp(-((-floor(gausswindow/2):floor(gausswindow/2)).^2)/(2*gausssigma^2));
    tempfilter = tempfilter/sum(tempfilter); %normalize the filter

    % Extract group names from the data structure

 % Initialize storage vectors for results
    groupsVec = {};
    cellTypesVec = {};
    FRs_before = [];
    FRs_after = [];
    unitIDs = {};
    binned_FRs_before = {};  % Store time-binned firing rates (before)
    binned_FRs_after = {};   % Store time-binned firing rates (after)

     % Iterate over groups, mice, and units
    groupNames = fieldnames(all_data);
    for groupNum = 1:length(groupNames)
        groupName = groupNames{groupNum};
        mouseNames = fieldnames(all_data.(groupName));

        for mouseNum = 1:length(mouseNames)
            mouseName = mouseNames{mouseNum};
            cellIDs = fieldnames(all_data.(groupName).(mouseName));

            for cellID_num = 1:length(cellIDs)
                cellID = cellIDs{cellID_num};
                cellData = all_data.(groupName).(mouseName).(cellID);

                if any(strcmp(cell_types, cellData.Cell_Type)) && cellData.IsSingleUnit
                    if ~isfield(cellData, 'SpikeTimes_all') || isempty(cellData.SpikeTimes_all)
                        warning('Missing spike times for cell %s. Skipping.', cellID);
                        continue;
                    end

                    % Convert spike times from samples to seconds
                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Define bin edges for pre- and post-treatment periods
                    preBinEdges = max(0, moment - preTreatmentPeriod):timeBinSize:moment;
                    postBinEdges = moment:timeBinSize:(moment + postTreatmentPeriod);

                    % Compute binned firing rates for both periods
                    FR_bins_before = histcounts(spikeTimes, preBinEdges) / timeBinSize;
                    FR_bins_after = histcounts(spikeTimes, postBinEdges) / timeBinSize;

                    % Smooth the binned firing rates using the Gaussian filter
                    FR_bins_before = conv(FR_bins_before, tempfilter, 'same');
                    FR_bins_after = conv(FR_bins_after, tempfilter, 'same');

                    % Store the average firing rates (bulk comparison)
                    FR_before = mean(FR_bins_before);
                    FR_after = mean(FR_bins_after);

                    % Store data in vectors and cells
                    FRs_before(end+1,1) = FR_before;
                    FRs_after(end+1,1) = FR_after;
                    groupsVec{end+1,1} = groupName;
                    cellTypesVec{end+1,1} = cellData.Cell_Type;
                    unitIDs{end+1,1} = cellID;
                    binned_FRs_before{end+1,1} = FR_bins_before;
                    binned_FRs_after{end+1,1} = FR_bins_after;
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
