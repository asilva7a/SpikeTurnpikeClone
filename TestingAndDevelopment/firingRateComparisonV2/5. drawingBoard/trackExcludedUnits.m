function [excludedUnits, excludedTable] = trackExcludedUnits(cellDataStruct, unitFilter, outlierFilter)
% trackExcludedUnits: Tracks units excluded from analysis and their reasons
%
% Inputs:
% - cellDataStruct: Data structure containing unit data
% - unitFilter: 'single', 'multi', or 'both'
% - outlierFilter: true/false for outlier exclusion
%
% Outputs:
% - excludedUnits: Structure containing excluded unit information
% - excludedTable: Table format of excluded units for easy export

% Initialize exclusion tracking
excludedUnits = struct('UnitID', {}, 'Recording', {}, 'Group', {}, 'ExclusionReason', {});
excludedCount = 1;

% Loop through all groups, recordings, and units
groupNames = fieldnames(cellDataStruct);
for g = 1:length(groupNames)
    groupName = groupNames{g};
    recordings = fieldnames(cellDataStruct.(groupName));
    
    for r = 1:length(recordings)
        recordingName = recordings{r};
        units = fieldnames(cellDataStruct.(groupName).(recordingName));
        
        for u = 1:length(units)
            unitID = units{u};
            unitData = cellDataStruct.(groupName).(recordingName).(unitID);
            
            % Track outlier exclusions
            if outlierFilter && isfield(unitData, 'isOutlierExperimental') && unitData.isOutlierExperimental == 1
                excludedUnits(excludedCount).UnitID = unitID;
                excludedUnits(excludedCount).Recording = recordingName;
                excludedUnits(excludedCount).Group = groupName;
                excludedUnits(excludedCount).ExclusionReason = 'Outlier';
                excludedCount = excludedCount + 1;
                continue;
            end
            
            % Track unit type filter exclusions
            isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
            if (strcmp(unitFilter, 'single') && ~isSingleUnit) || (strcmp(unitFilter, 'multi') && isSingleUnit)
                excludedUnits(excludedCount).UnitID = unitID;
                excludedUnits(excludedCount).Recording = recordingName;
                excludedUnits(excludedCount).Group = groupName;
                excludedUnits(excludedCount).ExclusionReason = sprintf('Unit Type Mismatch (Filter: %s)', unitFilter);
                excludedCount = excludedCount + 1;
                continue;
            end
            
            % Track missing fields
            if ~isfield(unitData, 'psthSmoothed') || ~isfield(unitData, 'responseType')
                excludedUnits(excludedCount).UnitID = unitID;
                excludedUnits(excludedCount).Recording = recordingName;
                excludedUnits(excludedCount).Group = groupName;
                excludedUnits(excludedCount).ExclusionReason = 'Missing Required Fields';
                excludedCount = excludedCount + 1;
                continue;
            end
            
            % Track mostly silent/zero units
            if isfield(unitData, 'responseType') && ...
               (strcmp(unitData.responseType, 'MostlySilent') || strcmp(unitData.responseType, 'MostlyZero'))
                excludedUnits(excludedCount).UnitID = unitID;
                excludedUnits(excludedCount).Recording = recordingName;
                excludedUnits(excludedCount).Group = groupName;
                excludedUnits(excludedCount).ExclusionReason = sprintf('Response Type: %s', unitData.responseType);
                excludedCount = excludedCount + 1;
                continue;
            end
        end
    end
end

% Convert to table format if exclusions exist
if ~isempty(excludedUnits)
    excludedTable = struct2table(excludedUnits);
    
    % Generate summary statistics
    fprintf('\nExclusion Summary:\n');
    summary = groupcounts(excludedTable, 'ExclusionReason');
    disp(summary);
    
    fprintf('\nExclusions by Group:\n');
    groupSummary = groupcounts(excludedTable, {'Group', 'ExclusionReason'});
    disp(groupSummary);
else
    excludedTable = table();
    fprintf('No units were excluded from the analysis.\n');
end

end
