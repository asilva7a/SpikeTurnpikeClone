function data_table_FR = label_responsive_units_fun(all_data, cell_types, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Define Boxcar smoothing window
    boxcarWindow = [1 1 1 1 1];  

    % Initialize storage vectors
    groupsVec = {};
    cellTypesVec = {};
    FRs_before = [];
    FRs_after = [];
    unitIDs = {};
    binned_FRs_before = {};  
    binned_FRs_after = {};   
    significanceVec = {};  % Store significance results

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
                    FR_before = calculate_FR(spikeTimes, preBinEdges, boxcarWindow);
                    FR_after = calculate_FR(spikeTimes, postBinEdges, boxcarWindow);

                    % Handle missing data
                    FR_before = handle_missing_data(FR_before);
                    FR_after = handle_missing_data(FR_after);

                    % Perform non-parametric t-test (Wilcoxon signed-rank)
                    [p, ~] = ranksum(FR_before, FR_after);

                    % Store results and metadata
                    significanceVec{end+1, 1} = p;
                    FRs_before(end+1, 1) = mean(FR_before);
                    FRs_after(end+1, 1) = mean(FR_after);
                    groupsVec{end+1, 1} = groupName;
                    cellTypesVec{end+1, 1} = cellData.Cell_Type;
                    unitIDs{end+1, 1} = cellID;
                    binned_FRs_before{end+1, 1} = FR_before;
                    binned_FRs_after{end+1, 1} = FR_after;
                end
            end
        end
    end

    % Categorize units by response type based on the p-value
    responseTypeVec = categorize_units(FRs_before, FRs_after, significanceVec);

    % Create a table with the results
    data_table_FR = table(unitIDs, groupsVec, cellTypesVec, FRs_before, FRs_after, ...
                          binned_FRs_before, binned_FRs_after, significanceVec, responseTypeVec, ...
                          'VariableNames', {'UnitID', 'Group', 'CellType', 'FR_Before', 'FR_After', ...
                                            'Binned_FRs_Before', 'Binned_FRs_After', 'P_Value', 'ResponseType'});

    % Visualize the results
    visualize_results(FRs_before, FRs_after, binned_FRs_before, binned_FRs_after, significanceVec);
end

% Helper function to calculate firing rate with smoothing
function smoothed_FR = calculate_FR(spikeTimes, binEdges, smoothingWindow)
    % Compute histogram of spike times in the specified bins
    binned_FRs = histcounts(spikeTimes, binEdges) / diff(binEdges(1:2));

    % Apply boxcar smoothing using convolution
    smoothed_FR = conv(binned_FRs, smoothingWindow, 'same');
end

% Helper function to handle missing data
function FR = handle_missing_data(FR)
    if isempty(FR)
        FR = 0;
    end
end

% Function to categorize units based on response type and significance
function responseTypeVec = categorize_units(FRs_before, FRs_after, significanceVec)
    responseTypeVec = cell(length(FRs_before), 1);

    for i = 1:length(FRs_before)
        if significanceVec{i} < 0.05  % If p-value is significant
            if FRs_after(i) > FRs_before(i)
                responseTypeVec{i} = 'Increased';
            else
                responseTypeVec{i} = 'Decreased';
            end
        else
            responseTypeVec{i} = 'No Change';
        end
    end
end

% Function to visualize the results
function visualize_results(FRs_before, FRs_after, binned_FRs_before, binned_FRs_after, significanceVec)
    % Scatter Plot: Pre vs. Post Firing Rates
    figure;
    scatter(FRs_before, FRs_after, 'filled');
    xlabel('Firing Rate Before (Hz)');
    ylabel('Firing Rate After (Hz)');
    title('Pre vs. Post Firing Rates');
    line([min(FRs_before), max(FRs_before)], [min(FRs_before), max(FRs_before)], 'Color', 'r', 'LineStyle', '--');

    % Histogram of significant p-values
    significant_pvalues = cell2mat(significanceVec) < 0.05;
    figure;
    histogram(significant_pvalues, 'FaceColor', 'b');
    xlabel('Significant Units');
    ylabel('Count');
    title('Distribution of Significant Responses');
end

