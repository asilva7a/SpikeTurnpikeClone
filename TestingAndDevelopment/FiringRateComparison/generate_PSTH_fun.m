function generate_PSTH_fun(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod)
    % This function generates three types of PSTH plots:
    % 1. Overlay PSTHs for responsive units (Increased or Decreased).
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

    % Initialize containers for PSTHs
    allPSTHs = [];           % Store all PSTHs for mean ± SEM calculation
    responsivePSTHs = [];     % Store PSTHs for responsive units (Increased/Decreased)
    nonResponsivePSTHs = [];  % Store PSTHs for non-responsive units

    % Iterate through all groups and recordings
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

                % Use existing spike alignment and PSTH logic
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                %% Define PSTH time window around the moment of interest
                edges = (moment - prePeriod):binSize:(moment + postPeriod);  % Bin edges

                % Generate the PSTH for the current unit
                psthCounts = histcounts(spikeTimes, edges);  % Spike counts per bin

                % Smooth the PSTH using the provided smoothing window
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same') / binSize;

                % Store the PSTH for later aggregation
                allPSTHs = [allPSTHs; smoothedPSTH];

                % Classify and store PSTHs based on ResponseType
                if ismember(unitData.ResponseType, {'Increased', 'Decreased'})
                    responsivePSTHs = [responsivePSTHs; smoothedPSTH];
                else
                    nonResponsivePSTHs = [nonResponsivePSTHs; smoothedPSTH];
                end
            end
        end
    end

    %% Generate Plots
    % 1. Plot PSTHs for responsive units (overlayed)
    figure;
    subplot(3, 1, 1);
    plot_PSTHs_overlay(responsivePSTHs, edges, 'Responsive Units (Increased/Decreased)');
    
    % 2. Plot PSTHs for non-responsive units (overlayed)
    subplot(3, 1, 2);
    plot_PSTHs_overlay(nonResponsivePSTHs, edges, 'Non-Responsive Units');
    
    % 3. Plot mean ± SEM PSTH for all units
    subplot(3, 1, 3);
    plot_mean_sem_PSTH(allPSTHs, edges, 'Mean ± SEM PSTH (All Units)');
end

%% Helper Function: Plot PSTHs Overlayed
function plot_PSTHs_overlay(PSTHs, edges, titleStr)
    if isempty(PSTHs)
        title([titleStr, ' (No Units)']);
        return;
    end
    plot(edges(1:end-1), PSTHs', 'Color', [0.7 0.7 0.7]);  % Plot each PSTH in light gray
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(titleStr);
end

%% Helper Function: Plot Mean ± SEM PSTH
function plot_mean_sem_PSTH(PSTHs, edges, titleStr)
    if isempty(PSTHs)
        title([titleStr, ' (No Units)']);
        return;
    end
    meanPSTH = mean(PSTHs, 1);  % Mean across units
    semPSTH = std(PSTHs, [], 1) / sqrt(size(PSTHs, 1));  % Standard error of the mean

    % Plot the mean PSTH with SEM as shaded area
    hold on;
    fill([edges(1:end-1), fliplr(edges(1:end-1))], ...
         [meanPSTH + semPSTH, fliplr(meanPSTH - semPSTH)], ...
         [0.8 0.8 1], 'EdgeColor', 'none');  % Light blue shaded area for SEM
    plot(edges(1:end-1), meanPSTH, 'k', 'LineWidth', 2);  % Mean PSTH in black
    hold off;
    xlabel('Time (s)');
    ylabel('Firing Rate (Hz)');
    title(titleStr);
end
