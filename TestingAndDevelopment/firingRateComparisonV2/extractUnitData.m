function cellData_Struct = extractUnitData(all_data)
% extractUnitData 
%   Does what is says on the box
%   Pulls out the firing rate from the all_data struct for one unit
 
    % Pre-load original cell data
    cellData = all_data.Pvalb.pvalb_hctztreat_0008_rec1.cid314;

    % Generate struct for storing extracted data and future analysis
    cellData_Struct = struct();

    % Label fields for struct
    groupName = fieldnames(cellData);
    recordingName = fieldnames(cellData.(groupName));
    unitID = fieldnames(cellData.(groupName).(recordingName));
    unitData = cellData.(groupName).(recordingName).(unitID);    

    % Extract Data
    spikeTimes = unitData.spikeTimes;
    samplingFrequency = unitData.Sampling_Frequency;
    cellType = unitData.Cell_Type;
    isSingleUnit = unitData.IsSingleUnit;
        
     % Store all relevant data in the responsive_units_struct
        cellData_Struct.(groupName).(recordingName).(unitID) = struct( ...
            'spikeTimes_All', spikeTimes, ...
            'samplingFrequency', samplingFrequency, ...
            'cellType', cellType, ...
            'isSingleUnit', isSingleUnit, ...
            'frAvg', mean(firingRate), ...
            'pValue', pValue, ...
            'responseType', responseType, ...
            'recording', recordingName, ...
            'binWidth', binWidth, ...
            'recordingLength', Recording_Duration ...
             );

end