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
                unitName = unitNames{u};
                unitData = all_data.(groupName).(recordingName).(unitName);
                spikeTimes = unitData.SpikeTimes_all / unitData.Sampling_Frequency;

                % Calculate the PSTH for this unit
                psthCounts = histcounts(spikeTimes, ...
                    moment - prePeriod : binSize : moment + postPeriod);
                smoothedPSTH = conv(psthCounts, smoothingWindow, 'same');

                % Find the response type of the current unit
                unitIndex = find(strcmp(unitIDs, unitName));
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


