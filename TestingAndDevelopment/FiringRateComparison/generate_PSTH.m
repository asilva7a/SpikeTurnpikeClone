function generate_PSTH(all_data, binSize, smoothingWindow, moment, prePeriod, postPeriod, responseTypeVec, unitIDs)
    % Initialize containers for PSTHs based on response types
    increasedPSTHs = {};  
    decreasedPSTHs = {};  
    noChangePSTHs = {};  

    % Iterate over all groups and units to generate PSTHs
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordingNames = fieldnames(all_data.(groupName));

        for r = 1:length(recordingNames)
            recordingName = recordingNames{r};
            unitNames = fieldnames(all_data.(groupName).(recordingName));

            for u = 1:length(unitNames)
                unitName = strtrim(unitNames{u});  % Ensure no extra spaces
                unitData = all_data.(groupName).(recordingName).(unitName);
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Calculate the PSTH for this unit
                psthCounts = histcounts(spikeTimes, ...
                    moment - prePeriod : binSize : moment + postPeriod);
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');

                % Debugging: Check the unit name and IDs
                disp(['Current unit name: ', unitName]);
                disp('Available unit IDs:');
                disp(unitIDs);

                % Find the response type
                unitIndex = find(strcmpi(unitIDs, unitName), 1);

                % Handle cases where the unit is not found
                if isempty(unitIndex)
                    warning('Unit %s not found in unitIDs. Skipping.', unitName);
                    continue;  % Skip this unit
                end

                % Get the response type for the matched unit
                responseType = responseTypeVec{unitIndex};

                % Store the PSTH based on the response type
                switch responseType
                    case 'Increased'
                        increasedPSTHs{end+1} = smoothedPSTH;
                    case 'Decreased'
                        decreasedPSTHs{end+1} = smoothedPSTH;
                    case 'No Change'
                        noChangePSTHs{end+1} = smoothedPSTH;
                end
            end
        end
    end

    % Plot the grouped PSTHs
    plot_grouped_PSTHs(increasedPSTHs, decreasedPSTHs, noChangePSTHs);
end

function plot_grouped_PSTHs(increasedPSTHs, decreasedPSTHs, noChangePSTHs)
    % Plot PSTHs for Increased units
    figure;
    subplot(1, 3, 1);
    hold on;
    for i = 1:length(increasedPSTHs)
        plot(increasedPSTHs{i}, 'LineWidth', 1.5);
    end
    title('Increased Units');
    xlabel('Time Bin');
    ylabel('Firing Rate (Hz)');
    hold off;

    % Plot PSTHs for Decreased units
    subplot(1, 3, 2);
    hold on;
    for i = 1:length(decreasedPSTHs)
        plot(decreasedPSTHs{i}, 'LineWidth', 1.5);
    end
    title('Decreased Units');
    xlabel('Time Bin');
    ylabel('Firing Rate (Hz)');
    hold off;

    % Plot PSTHs for No Change units
    subplot(1, 3, 3);
    hold on;
    for i = 1:length(noChangePSTHs)
        plot(noChangePSTHs{i}, 'LineWidth', 1.5);
    end
    title('No Change Units');
    xlabel('Time Bin');
    ylabel('Firing Rate (Hz)');
    hold off;
end
``
