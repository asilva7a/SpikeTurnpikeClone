function data_table_FR = label_responsive_units_fun(all_data, cell_types, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Gaussian filter for temporal smoothing
    gausssigma = 1;  
    gausswindow = 5;  
    tempfilter = exp(-((-floor(gausswindow/2):floor(gausswindow/2)).^2) / (2*gausssigma^2));
    tempfilter = tempfilter / sum(tempfilter);  

    % Initialize storage vectors
    groupsVec = {};
    cellTypesVec = {};
    FRs_before = [];
    FRs_after = [];
    unitIDs = {};
    binned_FRs_before = {};  
    binned_FRs_after = {};   
    FanoFactors_before = []; 
    FanoFactors_after = [];  
    bootResults = {};  % Store bootstrapped differences for visualization

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

                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Define bin edges for pre- and post-treatment periods
                    preBinEdges = max(0, moment - preTreatmentPeriod):binSize:moment;
                    postBinEdges = moment:binSize:(moment + postTreatmentPeriod);

                    % Calculate firing rates before and after treatment
                    FR_before = calculate_FR(spikeTimes, preBinEdges);
                    FR_after = calculate_FR(spikeTimes, postBinEdges);

                    % Handle missing data
                    FR_before = handle_missing_data(FR_before);
                    FR_after = handle_missing_data(FR_after);

                    % Perform bootstrapping
                    boot_diffs = bootstrap_difference(FR_before, FR_after);

                    % Store results and metadata
                    FanoFactors_before(end+1, 1) = var(FR_before) / mean(FR_before);
                    FanoFactors_after(end+1, 1) = var(FR_after) / mean(FR_after);
                    bootResults{end+1, 1} = boot_diffs;
                    FRs_before(end+1, 1) = FR_before;
                    FRs_after(end+1, 1) = FR_after;
                    groupsVec{end+1, 1} = groupName;
                    cellTypesVec{end+1, 1} = cellData.Cell_Type;
                    unitIDs{end+1, 1} = cellID;
                    binned_FRs_before{end+1, 1} = FR_before;
                    binned_FRs_after{end+1, 1} = FR_after;
                end
            end
        end
    end

    % Categorize units by response type
    responseTypeVec = categorize_units(FRs_before, FRs_after);

    % Label units and store output in a 2D cell array
    cidArray = label_units_by_response(responseTypeVec, unitIDs);

    % Create a table with the results
    data_table_FR = table(unitIDs, groupsVec, cellTypesVec, FRs_before, FRs_after, ...
                          binned_FRs_before, binned_FRs_after, FanoFactors_before, FanoFactors_after, responseTypeVec, ...
                          'VariableNames', {'UnitID', 'Group', 'CellType', 'FR_Before', 'FR_After', ...
                                            'Binned_FRs_Before', 'Binned_FRs_After', 'FanoFactor_Before', 'FanoFactor_After', 'ResponseType'});

    % Visualize the results
    visualize_results(FRs_before, FRs_after, FanoFactors_before, FanoFactors_after, binned_FRs_before, binned_FRs_after, bootResults);
end

% Helper function to calculate firing rate
function avg_FR = calculate_FR(spikeTimes, binEdges)
    binned_FRs = histcounts(spikeTimes, binEdges) / diff(binEdges(1:2));
    avg_FR = mean(binned_FRs);
    if isempty(avg_FR)
        avg_FR = 0;  % Return 0 if no spikes were found
    end
end

% Helper function to handle missing data
function FR = handle_missing_data(FR)
    if isempty(FR)
        FR = 0;
    end
end

% Function to perform bootstrapping
function boot_diffs = bootstrap_difference(FR_before, FR_after, nBootstraps)
    if nargin < 3, nBootstraps = 1000; end
    boot_diffs = zeros(nBootstraps, 1);
    for b = 1:nBootstraps
        resampled_before = FR_before(randi(length(FR_before), length(FR_before), 1));
        resampled_after = FR_after(randi(length(FR_after), length(FR_after), 1));
        boot_diffs(b) = mean(resampled_after) - mean(resampled_before);
    end
end

% Function to categorize units based on response type
function responseTypeVec = categorize_units(FRs_before, FRs_after)
    nBootstraps = 1000;
    alpha = 0.05;
    lower_CI = nan(length(FRs_before), 1);
    upper_CI = nan(length(FRs_before), 1);
    responseTypeVec = cell(length(FRs_before), 1);
    for i = 1:length(FRs_before)
        observed_diff = FRs_after(i) - FRs_before(i);
        boot_diffs = bootstrap_difference(FRs_before(i), FRs_after(i), nBootstraps);
        lower_CI(i) = prctile(boot_diffs, alpha / 2 * 100);
        upper_CI(i) = prctile(boot_diffs, (1 - alpha / 2) * 100);
        if lower_CI(i) > 0 || upper_CI(i) < 0
            if observed_diff > 0
                responseTypeVec{i} = 'Increased';
            else
                responseTypeVec{i} = 'Decreased';
            end
        else
            responseTypeVec{i} = 'No Change';
        end
    end
end

% Function to label units by response type
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
    cidArray = {positiveCIDs; negativeCIDs; nonResponsiveCIDs};
end

% Function to visualize the results
function visualize_results(FRs_before, FRs_after, FanoFactors_before, FanoFactors_after, binned_FRs_before, binned_FRs_after, bootResults)
    figure;
    scatter(FRs_before, FRs_after, 'filled');
    xlabel('Firing Rate Before (Hz)');
    ylabel('Firing Rate After (Hz)');
    title('Pre vs. Post Firing Rates');
    line([min(FRs_before), max(FRs_before)], [min(FRs_before), max(FRs_before)], 'Color', 'r', 'LineStyle', '--');
    [~, mostResponsiveIndex] = max(abs(FRs_after - FRs_before));
    boot_diffs = bootResults{mostResponsiveIndex};
    observed_diff = FRs_after(mostResponsiveIndex) - FRs_before(mostResponsiveIndex);
    figure;
    histogram(boot_diffs, 30, 'FaceColor', 'b');
    hold on;
    xline(observed_diff, 'r', 'LineWidth', 2);
    xlabel('Bootstrapped Difference');
    ylabel('Frequency');
    title('Bootstrapped Differences for Most Responsive Unit');
    legend('Bootstrap Distribution', 'Observed Difference');
    if ~isempty(FanoFactors_before) && ~isempty(FanoFactors_after)
        figure;
        subplot(1, 2, 1);
        histogram(FanoFactors_before, 'FaceColor', 'b');
        xlabel('Fano Factor');
        ylabel('Count');
        title('Fano Factors Before Treatment');
        subplot(1, 2, 2);
        histogram(FanoFactors_after, 'FaceColor', 'r');
        xlabel('Fano Factor');
        ylabel('Count');
        title('Fano Factors After Treatment');
    else
        disp('Fano Factor data is missing. Skipping Fano Factor histograms.');
    end
end
