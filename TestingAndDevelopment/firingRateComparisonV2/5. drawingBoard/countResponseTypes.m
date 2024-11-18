function countResponseTypes(cellDataStruct, unitFilter, outlierFilter)
    % Initialize counters
    increased = 0;
    decreased = 0;
    noChange = 0;
    
    % Process each group
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));
        
        % Process each recording
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Process each unit
            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
               
                % Check unit type
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if strcmp(unitFilter, 'single') && ~isSingleUnit || ...
                   strcmp(unitFilter, 'multi') && isSingleUnit
                    continue;
                end

                if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental
                    continue;
                end
                
                % Check response type
                if isfield(unitData, 'responseType')
                    switch unitData.responseType
                        case 'Increased'
                            increased = increased + 1;
                        case 'Decreased'
                            decreased = decreased + 1;
                        case 'No_Change'
                            noChange = noChange + 1;
                                
                    end
                end
            end
        end
    end
    
    % Display results
    fprintf('\nResponse Type Summary:\n');
    fprintf('-------------------\n');
    fprintf('Increased: %d units\n', increased);
    fprintf('Decreased: %d units\n', decreased);
    fprintf('No Change: %d units\n', noChange);
    fprintf('Total: %d units\n\n', increased + decreased + noChange);
    
    % Calculate percentages
    total = increased + decreased + noChange;
    if total > 0
        fprintf('Percentages:\n');
        fprintf('Increased: %.1f%%\n', (increased/total)*100);
        fprintf('Decreased: %.1f%%\n', (decreased/total)*100);
        fprintf('No Change: %.1f%%\n', (noChange/total)*100);
    end
end