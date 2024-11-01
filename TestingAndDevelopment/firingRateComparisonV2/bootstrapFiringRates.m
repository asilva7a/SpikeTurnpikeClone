function [bootstats] = get_bootstrapped_equalsamples(data, nruns, num_trials, param)
    % Perform bootstrapping n_runs times with an equal sample size of num_trials at the lower level.

    bootstats = NaN(nruns,1);  % Preallocate an array to store bootstrap statistics for each run.

    for i = 1:nruns  % Loop over each bootstrap iteration.
        a = size(data);  % Get the size of the input data matrix.
        num_lev1 = a(1);  % Determine the number of level-1 units (rows in the data matrix).

        temp = NaN(num_lev1, num_trials);  % Preallocate a temporary matrix to store resampled data.
        rand_lev1 = randi(num_lev1, num_lev1, 1);  % Randomly sample level-1 units with replacement.

        for j = 1:length(rand_lev1)  % Loop over each sampled level-1 unit.
            num_lev2 = find(~isnan(data(rand_lev1(j), :)), 1, 'last');  % Find the number of non-NaN trials in the sampled row.

            % Randomly sample num_trials from the non-NaN trials of the selected unit.
            rand_lev2 = randi(num_lev2, 1, num_trials);  

            % Store the resampled trials in the temporary matrix.
            temp(j, :) = data(rand_lev1(j), rand_lev2);  
        end

        % Calculate the specified statistic (mean or median) over all resampled values.
        if strcmp(param, 'mean')
            bootstats(i) = mean(temp(:));  % Flatten `temp` and calculate mean.
        elseif strcmp(param, 'median')
            bootstats(i) = median(temp(:));  % Flatten `temp` and calculate median.
        else
            disp('Unknown parameter. Use mean or median or write a new one.');  % Display error message for invalid parameter.
            return  % Exit the function if an unknown parameter is provided.
        end

        % Display the progress of the bootstrapping process.
        disp(['Sample ' num2str(i) ' completed.']);
    end
end

function [p_boot, bootstats, bootstats_center, bootstats_sem] = get_bootstrap_results_equalsamples(data1, data2, n_runs, num_trials, param)
    % Perform hierarchical bootstrapping on a 2-level dataset with two groups to be compared,
    % following the method described in Saravanan et al. 2019.
    %
    % Inputs:
    %   - data1, data2: Data matrices for each group to compare, where rows represent level 1
    %     units and columns represent level 2 units (may contain NaNs if units have different
    %     numbers of level 2 data points, with NaNs expected at the end of rows).
    %   - n_runs: Number of bootstrap samples to draw.
    %   - num_trials: Number of samples to draw per bootstrap iteration at the lower level.
    %   - param: Statistic to calculate for each bootstrap ('mean' or 'median').
    %
    % Outputs:
    %   - p_boot: Probability that the mean/median of data2 >= mean/median of data1.
    %   - bootstats: Bootstrap distributions for data1 and data2.
    %   - bootstats_center: Mean of the bootstrapped distributions for data1 and data2.
    %   - bootstats_sem: Standard error of the mean of the bootstrapped distributions.

    bootstats = NaN(2, n_runs);  % Preallocate for bootstrap results from data1 and data2.

    % Calculate bootstrapped samples for data1 and data2 using the helper function.
    bootstats(1, :) = get_bootstrapped_equalsamples(data1, n_runs, num_trials, param);  % For group 1
    bootstats(2, :) = get_bootstrapped_equalsamples(data2, n_runs, num_trials, param);  % For group 2

    % Calculate the probability that bootstrap statistics of data2 >= data1.
    p_boot = get_direct_prob(bootstats(1, :), bootstats(2, :));

    % Calculate the mean and SEM of the bootstrapped distributions.
    bootstats_sem = std(bootstats, '', 2);  % Standard error of the mean for each group.
    bootstats_center = mean(bootstats, 2);  % Mean of bootstrap distributions for each group.

    % Check for NaNs in bootstats_center to detect sampling issues
    % and alert if encountered.
    if isnan(bootstats_center(1)) || isnan(bootstats_center(2))
        disp('NaN values are messing up sampling - check matrices and try again.');
    end
end

% Helper Function: Perform bootstrapping at a single hierarchical level.
function [bootstats] = get_bootstrapped_equalsamples(data, n_runs, num_trials, param)
    % Perform bootstrapping n_runs times with an equal sample size of num_trials at the lower level.

    bootstats = NaN(n_runs, 1);  % Preallocate array to store bootstrap statistics for each run.

    for i = 1:n_runs  % Loop over each bootstrap iteration.
        a = size(data);  % Get the size of the input data matrix.
        num_lev1 = a(1);  % Number of level-1 units (rows in the data matrix).

        temp = NaN(num_lev1, num_trials);  % Preallocate temporary matrix for resampled data.
        rand_lev1 = randi(num_lev1, num_lev1, 1);  % Randomly sample level-1 units with replacement.

        for j = 1:length(rand_lev1)  % Loop over each sampled level-1 unit.
            num_lev2 = find(~isnan(data(rand_lev1(j), :)), 1, 'last');  % Find non-NaN data points in the row.
            
            % Randomly sample num_trials from the non-NaN trials of each selected unit.
            rand_lev2 = randi(num_lev2, 1, num_trials); 
            
            % Store the resampled trials in the temporary matrix.
            temp(j, :) = data(rand_lev1(j), rand_lev2);
        end

        % Calculate the specified statistic (mean or median) across all resampled values.
        if strcmp(param, 'mean')
            bootstats(i) = mean(temp(:));  % Flatten temp and calculate mean.
        elseif strcmp(param, 'median')
            bootstats(i) = median(temp(:));  % Flatten temp and calculate median.
        else
            disp('Unknown parameter. Use "mean" or "median".');  % Alert if param is not mean or median.
            return
        end

        % Display progress of the bootstrapping process.
        disp(['Sample ' num2str(i) ' completed.']);
    end
end

% Helper Function: Calculate the probability that values in dist2 are greater than or equal to dist1.
function p = get_direct_prob(dist1, dist2)
    % Calculate the probability that dist2 >= dist1 in bootstrap samples.
    p = mean(dist2 >= dist1);
end
