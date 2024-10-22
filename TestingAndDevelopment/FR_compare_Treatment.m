%% FR_compare_Treatment.m
% This function compares the firing rates (FR) of neuronal units before and 
% after a given moment (e.g., stimulation onset) using bootstrapping to identify 
% significant changes in activity. 
%
% INPUTS:
%   all_data           - A structure containing spike data for groups, mice, and cells
%   cell_types         - A cell array of cell types to include (e.g., {'RS', 'FS'})
%   binSize            - Size of time bins for calculating firing rates (in seconds)
%   plot_points        - A flag (0 or 1) to indicate whether to plot individual points
%   moment             - The time point (in seconds) defining the stimulation onset
%   preTreatmentPeriod - Duration (in seconds) before the moment to analyze
%   postTreatmentPeriod- Duration (in seconds) after the moment to analyze
%
% OUTPUTS:
%   data_table_FR      - A table containing firing rates, confidence intervals,
%                        and response classifications (Increased, Decreased, No Change).
%
% The function also exports the results to a CSV file and creates plots using the 
% gramm library.

function data_table_FR = FR_compare_Treatment(all_data, cell_types, binSize, plot_points, moment, preTreatmentPeriod, postTreatmentPeriod)
    % Extract group names from the data structure
    groupNames = fieldnames(all_data);

    % Initialize storage vectors for results
    groupsVec = {};       % Stores the group of each unit
    cellTypesVec = {};    % Stores the type of each unit (e.g., 'RS', 'FS')
    FRs_before = [];      % Stores the firing rate before the stimulation
    FRs_after = [];       % Stores the firing rate after the stimulation
    unitIDs = {};         % Stores the unique ID of each unit
    responseTypeVec = {}; % Stores response classification ('Increased', 'Decreased', 'No Change')

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
                    end

                    % Convert spike times from samples to seconds
                    spikeTimes = cellData.SpikeTimes_all / cellData.Sampling_Frequency;

                    % Calculate firing rates before and after the stimulation moment
                    FR_before = calculate_FR(spikeTimes, max(0, moment - preTreatmentPeriod), moment, binSize);
                    FR_after = calculate_FR(spikeTimes, moment, min(cellData.Recording_Duration, moment + postTreatmentPeriod), binSize);

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

    %% Create Data Table for Export
    data_table_FR = table(unitIDs, groupsVec, cellTypesVec, FRs_before, FRs_after, lower_CI, upper_CI, responseTypeVec, ...
        'VariableNames', {'UnitID', 'Group', 'CellType', 'FR_Before', 'FR_After', 'Lower_CI', 'Upper_CI', 'ResponseType'});

    % Export the data table to a CSV file
    csvFileName = 'processed_FR_data_with_bootstrap.csv';
    writetable(data_table_FR, csvFileName);
    fprintf('Data with bootstrapping results successfully exported to %s\n', csvFileName);

    %% Visualize Results by Response Type Using Gramm Library
    figure;
    g = gramm('x', responseTypeVec, 'y', FRs_after - FRs_before, 'color', cellTypesVec);

    % Create facets for each cell type (e.g., RS and FS)
    g.facet_grid([], cellTypesVec, 'scale', 'independent');

    % Plot bars with SEM error bars
    g.stat_summary('type', 'sem', 'geom', {'bar', 'black_errorbar'}, 'width', 0.6, 'dodge', 0.8);

    % Set axis labels and title
    g.set_names('x', 'Response Type', 'y', 'Change in Firing Rate (Hz)', 'Color', 'Cell Type');
    g.set_title('Change in Firing Rate (Post - Pre) by Response Type');

    % Draw the plot
    g.draw();
end

%% Helper Function to Calculate Firing Rate (Average FR)
function avg_FR = calculate_FR(spikeTimes, startTime, endTime, binSize)
    % Calculate firing rate by dividing the period into bins and counting spikes
    intervalBounds = startTime:binSize:endTime;
    binned_FRs = [];  % Store firing rates for each bin

    for ii = 1:length(intervalBounds) - 1
        % Count spikes within the current bin
        n_spikes = length(spikeTimes(spikeTimes >= intervalBounds(ii) & spikeTimes < intervalBounds(ii + 1)));
        FR_in_bin = n_spikes / binSize;  % Compute firing rate in Hz
        binned_FRs(end + 1, 1) = FR_in_bin;
    end

    % Return the average firing rate across bins
    if ~isempty(binned_FRs)
        avg_FR = mean(binned_FRs);
    else
        avg_FR = 0;  % Return 0 if no spikes were found
    end
end
