function ci = bootstrapFiringRates(cellDataStruct, N_bootstrap)
    % Set number of bootstrap iterations if not specified
    if nargin < 2
        N_bootstrap = 10000;
    end

    % Initialize array to store bootstrap means
    bootstrap_means = NaN(N_bootstrap, 1); 

    % Plot the original firing rate distribution for a sample unit
    sampleFiringRates = getFiringRates(cellDataStruct.Emx.emx_hctztreat_0001_rec1);
    plotFiringRateDistribution(sampleFiringRates, 'Original Firing Rates Distribution');

    % Bootstrap sampling
    for i = 1:N_bootstrap
        % Resample the data structure hierarchy
        resampled_data = resampleHierarchy(cellDataStruct);

        % Calculate mean firing rate for this bootstrap iteration
        if ~isempty(resampled_data.firing_rates)
            mean_firing_rate = calculateMeanFiringRate(resampled_data);
        else
            mean_firing_rate = NaN;
        end

        % Store the mean for this bootstrap iteration
        bootstrap_means(i) = mean_firing_rate;
    end

    % Remove NaN values in case of empty resamples
    bootstrap_means = bootstrap_means(~isnan(bootstrap_means));

    % Plot the bootstrap mean distribution
    figure;
    histogram(bootstrap_means, 50, 'FaceColor', 'b', 'EdgeColor', 'k');
    xlabel('Bootstrap Means');
    ylabel('Frequency');
    title('Distribution of Bootstrap Means');
    
    % Calculate confidence intervals
    if isempty(bootstrap_means)
        warning('All bootstrap samples are empty.');
        ci = [NaN, NaN];
    else
        ci = prctile(bootstrap_means, [2.5, 97.5]);
    end
    fprintf('95%% Confidence Interval: [%f, %f]\n', ci(1), ci(2));
end

function resampled_data = resampleHierarchy(dataStruct)
    % Resample group, recording, and unit levels in the structure

    % Extract available groups
    groupNames = fieldnames(dataStruct);
    resampled_data.groups = datasample(groupNames, numel(groupNames), 'Replace', true);
    
    % Initialize resampled data struct
    resampled_data.firing_rates = [];

    % Resample recordings and units within each group
    for g = 1:numel(resampled_data.groups)
        groupName = resampled_data.groups{g};
        recordings = fieldnames(dataStruct.(groupName));
        resampled_recordings = datasample(recordings, numel(recordings), 'Replace', true);

        for r = 1:numel(resampled_recordings)
            recordingName = resampled_recordings{r};
            units = fieldnames(dataStruct.(groupName).(recordingName));
            resampled_units = datasample(units, numel(units), 'Replace', true);

            % Collect firing rates from resampled units
            for u = 1:numel(resampled_units)
                unitID = resampled_units{u};
                firingRates = dataStruct.(groupName).(recordingName).(unitID).psthSmoothed;
                resampled_data.firing_rates = [resampled_data.firing_rates; firingRates];
            end
        end
    end
    
    % Plot firing rate distribution of resampled data for sanity check
    plotFiringRateDistribution(resampled_data.firing_rates, 'Resampled Firing Rates Distribution');
end

function mean_firing_rate = calculateMeanFiringRate(data)
    % Calculate mean firing rate across all resampled data
    if isempty(data.firing_rates)
        mean_firing_rate = NaN;
    else
        mean_firing_rate = mean(data.firing_rates);
    end
end

function plotFiringRateDistribution(firing_rates, titleText)
    % Helper function to plot a histogram of firing rates
    figure;
    histogram(firing_rates, 50, 'FaceColor', 'g', 'EdgeColor', 'k');
    xlabel('Firing Rate (spikes/s)');
    ylabel('Frequency');
    title(titleText);
end

function firingRates = getFiringRates(recordingStruct)
    % Extract firing rates from all units within a specific recording
    unitNames = fieldnames(recordingStruct);
    firingRates = [];
    
    for i = 1:numel(unitNames)
        unitData = recordingStruct.(unitNames{i});
        if isfield(unitData, 'psthSmoothed')
            firingRates = [firingRates; unitData.psthSmoothed];
        end
    end
end


