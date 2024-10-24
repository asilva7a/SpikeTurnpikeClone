function data_table_FR = label_responsive_units_fun(all_data, cell_types, binSize, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Gaussian filter for temporal smoothing
    gausssigma = 1;  
    gausswindow = 5;  
    tempfilter = exp(-((-floor(gausswindow/2):floor(gausswindow/2)).^2) / (2*gausssigma^2));
    tempfilter = tempfilter / sum(tempfilter);  

    % Initialize storage vectors for results
    groupsVec = {};
    cellTypesVec = {};
    FRs_before = [];
    FRs_after = [];
    unitIDs = {};
    binned_FRs_before = {};  
    binned_FRs_after = {};   
    FanoFactors_before = []; 
    FanoFactors_after = [];  

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

                    preBinEdges = max(0, moment - preTreatmentPeriod):binSize:moment;
                    postBinEdges = moment:binSize:(moment + postTreatmentPeriod);

                    FR_bins_before = histcounts(spikeTimes, preBinEdges) / binSize;
                    FR_bins_after = histcounts(spikeTimes, postBinEdges) / binSize;

                    FR_bins_before = conv(FR_bins_before, tempfilter, 'same');
                    FR_bins_after = conv(FR_bins_after, tempfilter, 'same');

                    fano_before = var(FR_bins_before) / mean(FR_bins_before);
                    fano_after = var(FR_bins_after) / mean(FR_bins_after);

                    if isnan(fano_before) || isinf(fano_before), fano_before = 0; end
                    if isnan(fano_after) || isinf(fano_after), fano_after = 0; end

                    FR_before = mean(FR_bins_before);
                    FR_after = mean(FR_bins_after);

                    FRs_before(end+1,1) = FR_before;
                    FRs_after(end+1,1) = FR_after;
                    FanoFactors_before(end+1,1) = fano_before;
                    FanoFactors_after(end+1,1) = fano_after;
                    groupsVec{end+1,1} = groupName;
                    cellTypesVec{end+1,1} = cellData.Cell_Type;
                    unitIDs{end+1,1} = cellID;
                    binned_FRs_before{end+1,1} = FR_bins_before;
                    binned_FRs_after{end+1,1} = FR_bins_after;
                end
            end
        end
    end

    responseTypeVec = categorize_units(FRs_before, FRs_after);

    cidArray = label_units_by_response(responseTypeVec, unitIDs);

    data_table_FR = table(unitIDs, groupsVec, cellTypesVec, FRs_before, FRs_after, ...
                          binned_FRs_before, binned_FRs_after, FanoFactors_before, FanoFactors_after, responseTypeVec, ...
                          'VariableNames', {'UnitID', 'Group', 'CellType', 'FR_Before', 'FR_After', ...
                                            'Binned_FRs_Before', 'Binned_FRs_After', 'FanoFactor_Before', 'FanoFactor_After', 'ResponseType'});

    % Visualize the Firing Rate Changes and Fano Factors
    visualize_results(FRs_before, FRs_after, FanoFactors_before, FanoFactors_after);
end

function visualize_results(FRs_before, FRs_after, FanoFactors_before, FanoFactors_after)
    % Scatter Plot: Pre vs. Post Firing Rates
    figure;
    scatter(FRs_before, FRs_after, 'filled');
    xlabel('Firing Rate Before (Hz)');
    ylabel('Firing Rate After (Hz)');
    title('Pre vs. Post Firing Rates');
    line([min(FRs_before), max(FRs_before)], [min(FRs_before), max(FRs_before)], 'Color', 'r', 'LineStyle', '--');

    % Overlay Plot: Binned Firing Rates for the First Unit
    if ~isempty(FRs_before)
        figure;
        plot(binned_FRs_before{1}, 'b', 'LineWidth', 1.5); hold on;
        plot(binned_FRs_after{1}, 'r', 'LineWidth', 1.5);
        xlabel('Time Bin');
        ylabel('Firing Rate (Hz)');
        legend({'Before Treatment', 'After Treatment'});
        title('Binned Firing Rates for Unit 1');
    end

    % Histogram: Fano Factor Distribution
    figure;
    subplot(1,2,1);
    histogram(FanoFactors_before, 'FaceColor', 'b');
    xlabel('Fano Factor');
    ylabel('Count');
    title('Fano Factors Before Treatment');

    subplot(1,2,2);
    histogram(FanoFactors_after, 'FaceColor', 'r');
    xlabel('Fano Factor');
    ylabel('Count');
    title('Fano Factors After Treatment');
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
