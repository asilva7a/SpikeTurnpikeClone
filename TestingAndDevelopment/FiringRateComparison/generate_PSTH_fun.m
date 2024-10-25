function generate_PSTH_fun(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod)
    % This function generates three types of PSTH plots:
    % 1. Overlay PSTHs for responsive units (Increased/Decreased).
    % 2. Overlay PSTHs for non-responsive units.
    % 3. Mean ± SEM PSTHs for all units.
    %
    % INPUTS:
    %   all_data        - A structure containing spike data for groups, recordings, and units
    %   binSize         - Size of time bins for PSTHs (in seconds)
    %   smoothingWindow - A vector specifying the smoothing window (e.g., [1 1 1 1 1])
    %   moment          - The time point (in seconds) defining the alignment moment (e.g., stimulus onset)
    %   prePeriod       - Time before the moment to include in the PSTH (in seconds)
    %   postPeriod      - Time after the moment to include in the PSTH (in seconds)

    % Preallocate containers for PSTHs
    allPSTHs = [];           % Store all PSTHs for mean ± SEM calculation
    responsivePSTHs = [];     % Store PSTHs for responsive units (Increased/Decreased)
    nonResponsivePSTHs = [];  % Store PSTHs for non-responsive units

    % Define bin edges for PSTHs
    edges = (moment - prePeriod):binSize:(moment + postPeriod);  % Bin edges
    binCenters = edges(1:end-1) + binSize / 2;  % Compute bin centers for plotting

    % Iterate through all groups, recordings, and units
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            % Process each unit within the current recording
            for u = 1:length(unitNames)
                unitName = unitNames{u};
                unitData = all_data.(groupName).(recordingName).(unitName);

                % Align and process spike times
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Generate PSTH for the current unit
                psthCounts = histcounts(spikeTimes, edges);  % Spike counts per bin

                % Apply smoothing with convolution
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same') / binSize;

                % Store the PSTH for aggregation
                allPSTHs = [allPSTHs; smoothedPSTH];

                % Classify and store PSTH based on ResponseType
                % Initialize containers for PSTHs
                    responsivePSTHs = {};  % Store PSTHs for responsive units
                    nonResponsivePSTHs = {};  % Store PSTHs for non-responsive units

                    % Iterate over all units to classify and store PSTHs
                    for i = 1:length(responseTypeVec)
                        % Get the response type for the current unit
                        responseType = responseTypeVec{i};  

                        % Retrieve the smoothed PSTH for this unit (assuming it's pre-computed)
                        smoothedPSTH = binned_FRs_after{i};  

                        % Classify and store the PSTH based on the response type
                        if ismember(responseType, {'Increased', 'Decreased'})
                            responsivePSTHs{end+1} = smoothedPSTH;
                        else
                            nonResponsivePSTHs{end+1} = smoothedPSTH;
                        end
                    end
                end
            end
        end
    end

    %% Generate Plots
    figure;

    % 1. Overlay PSTHs for responsive units
    subplot(3, 1, 1);
    plot_PSTHs_overlay(responsivePSTHs, binCenters, 'Responsive Units (Increased/Decreased)');

    % 2. Overlay PSTHs for non-responsive units
    subplot(3, 1, 2);
    plot_PSTHs_overlay(nonResponsivePSTHs, binCenters, 'Non-Responsive Units');

    % 3. Mean ± SEM PSTH for all units
    subplot(3, 1, 3);
    plot_mean_sem_PSTH(allPSTHs, binCenters, 'Mean ± SEM PSTH (All Units)');
end

%% Helper Function: Plot Overlayed PSTHs
function plot_PSTHs_overlay(PSTHs, binCenters, titleStr)
    if isempty(PSTHs)
        title([titleStr, ' (No Units)']);
        return;
    end

    % Plot each PSTH in light gray
    plot(binCenters, PSTHs', 'Color', [0.7 0.7 0.7]);
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(titleStr);
    xlim([binCenters(1), binCenters(end)]);  % Adjust x-axis limits
end

%% Helper Function: Plot Mean ± SEM PSTH
function plot_mean_sem_PSTH(PSTHs, binCenters, titleStr)
    if isempty(PSTHs)
        title([titleStr, ' (No Units)']);
        return;
    end

    % Compute the mean and SEM of the PSTHs
    meanPSTH = mean(PSTHs, 1);
    semPSTH = std(PSTHs, [], 1) / sqrt(size(PSTHs, 1));

    % Plot the mean PSTH with SEM as a shaded area
    hold on;
    fill([binCenters, fliplr(binCenters)], ...
         [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
         [0.8 0.8 1], 'EdgeColor', 'none');  % Light blue shaded area for SEM
    plot(binCenters, meanPSTH, 'k', 'LineWidth', 2);  % Mean PSTH in black
    hold off;

    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(titleStr);
    xlim([binCenters(1), binCenters(end)]);  % Adjust x-axis limits
end
