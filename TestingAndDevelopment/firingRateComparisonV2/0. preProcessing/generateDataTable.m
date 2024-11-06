function [dataTable] = generateDataTable(cellDataStruct, dataFilePath)
% generateDataTable: Pulls out the unit data for a single recording into a preallocated table format.
%
%   Input:
%       cellDataStruct - Fully processed struct from analysis pipeline with all data.
%       dataFilePath - Path to the directory containing the cellDataStruct and related data.
%
%   Output:
%       dataTable - Table containing fields 'unitID', 'responseLabel', 
%                   'recordingName', 'groupName', 'groupTag', 'rawPSTH', 
%                   'smoothedPSTH', 'statTestMetaData'.

%% Load single recording; prepicked based on presence of highly responsive units
recordingID = cellDataStruct.Pvalb.pvalb_hCTZtreated_0008_rec1;

% Determine number of units to preallocate table size
    numUnits = length(recordingID);

    % Preallocate the table with appropriate data types
    dataTable = table('Size', [numUnits, 16], ...
                      'VariableTypes', {'double', 'string', 'string', ...
                                        'string', 'string', 'cell', 'cell', 'cell'}, ...
                      'VariableNames', {'unitID', 'responseLabel', 'recordingName', ...
                                        'groupName', 'groupTag', 'rawPSTH', ...
                                        'smoothedPSTH', 'statTestMetaData'});

    % Fill the preallocated table with NaNs or empty values
    dataTable.unitID(:) = NaN;
    dataTable.responseLabel(:) = "";
    dataTable.recordingName(:) = "";
    dataTable.groupName(:) = "";
    dataTable.groupTag(:) = "";
    dataTable.rawPSTH(:) = {[]};
    dataTable.smoothedPSTH(:) = {[]};
    dataTable.statTestMetaData(:) = {[]};

    % Populate the table by looping through cellDataStruct
    for i = 1:numUnits
        unit = recordingID(i);

        % Assign data for each unit into the preallocated table
        dataTable.unitID(i) = unit.unitID;
        dataTable.responseLabel(i) = unit.responseLabel;
        dataTable.recordingName(i) = unit.recordingName;
        dataTable.groupName(i) = unit.groupName;
        dataTable.groupTag(i) = unit.groupTag;
        dataTable.rawPSTH{i} = unit.rawPSTH;
        dataTable.smoothedPSTH{i} = unit.smoothedPSTH;
        dataTable.statTestMetaData{i} = unit.statTestMetaData;
    end

    % Save the table as a .mat file in the specified directory
    save(fullfile(dataFilePath, 'dataTable.mat'), 'dataTable');
end