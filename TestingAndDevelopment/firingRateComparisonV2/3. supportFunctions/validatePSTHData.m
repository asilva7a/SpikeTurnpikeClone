function validatePSTHData(dataStruct)
    % Validate if essential fields exist in the structure
    groupNames = fieldnames(dataStruct);

    if isempty(groupNames)
        error('PlotError:MissingGroups', 'No groups found in the structure.');
    end

    % Check the presence of recordings and units
    for g = 1:length(groupNames)
        group = groupNames{g};
        recordings = fieldnames(dataStruct.(group));

        if isempty(recordings)
            error('PlotError:MissingRecordings', 'No recordings found in Group: %s', group);
        end

        for r = 1:length(recordings)
            units = fieldnames(dataStruct.(group).(recordings{r}));

            if isempty(units)
                error('PlotError:MissingUnits', 'No units found in Recording: %s', recordings{r});
            end
        end
    end
end