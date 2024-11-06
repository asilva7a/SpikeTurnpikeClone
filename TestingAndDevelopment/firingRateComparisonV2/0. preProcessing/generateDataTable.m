function [dataTable] = generateDataTable(cellDataStruct, dataFilePath)
% generateDataTable: Pulls out the unit data for a single recording into a preallocated table format.
%
%   Input:
%       cellDataStruct - Fully processed struct from analysis pipeline with all data.
%       dataFilePath - Path to the directory containing the cellDataStruct and related data.
%
%   Output:
%       dataTable - Table containing fields 'unitID', 'responseType', 
%                   'recordingName', 'groupName', 'groupTag', 'psthRaw', 
%                   'psthSmoothed', 'testMetaData'.

%% Debugging: Preload data dir for function

%  Load the data
files = {'cellDataStruct.mat', 'cellDataStructPath.mat', 'dataFilePath.mat', ...
         'dataFolder.mat', 'figureFolder.mat'};
for i = 1:length(files)
    load(fullfile('/home/silva7a-local/Documents/MATLAB/SpikeTurnpikeClone/TestData/testVariables', files{i}));
end

%% Load single recording; pre-picked based on presence of highly responsive units
% Pull specific group from cellDataStruct, e.g., 'Pvalb' group
groupName = 'Pvalb';  % Set to 'Emx', 'Pvalb', or 'Control' based on the group being analyzed
recordingFields = fieldnames(cellDataStruct.(groupName));

% Specify which recording to extract (for example, pvalb_hCTZtreated_0008_rec1)
recordingField = 'pvalb_hCTZtreated_0008_rec1';  % Change this as needed
if ~ismember(recordingField, recordingFields)
    error('The recording %s was not found in the group %s.', recordingField, groupName);
end

% Extract the recording data and recording name
recordingID = cellDataStruct.(groupName).(recordingField);
recordingName = recordingField;  % Set recordingName as the field name

%% Determine group tag based on group name
if ismember(groupName, {'Emx', 'Pvalb'})
    groupTag = 'Experimental';
elseif strcmp(groupName, 'Control')
    groupTag = 'Control';
else
    error('Unknown group name. Expected Emx, Pvalb, or Control.');
end

%% Build table for storing data
% Determine number of units to preallocate table size
allFields = fieldnames(recordingID);
cidFields = allFields(contains(allFields, 'cid'));  % Filter for 'cid' fields only
numFields = numel(cidFields);

clear allFields 

% Display result
fprintf('Number of units in recording: %d\n', numFields);

% Preallocate the table with appropriate data types
dataTable = table('Size', [numFields, 8], ...
                  'VariableTypes', {'double', 'string', 'string', ...
                                    'string', 'string', 'cell', 'cell', 'cell'}, ...
                  'VariableNames', {'unitID', 'responseType', 'recordingName', ...
                                    'groupName', 'groupTag', 'psthRaw', ...
                                    'psthSmoothed', 'testMetaData'});

%% Fill table with data from single recording
% Populate the table by looping through each 'cid' field in recordingID
for g = 1:numFields
    unitField = cidFields{g};  % Get the field name (e.g., 'cid148')
    unit = recordingID.(unitField);  % Access the unit data by field name
    
    % Assign data for each unit into the preallocated table
    dataTable.unitID(g) = str2double(regexprep(unitField, '\D', ''));  % Extract numeric part of 'cid' field name
    dataTable.responseType(g) = unit.responseType;                     % Extract response label from unit field
    dataTable.recordingName(g) = recordingName;                        % Use recording name extracted from the field name
    dataTable.groupName(g) = groupName;                                % Use groupName as the groupName field
    dataTable.groupTag(g) = groupTag;                                  % Use the determined groupTag ('Experimental' or 'Control')
    dataTable.psthRaw{g} = unit.psthRaw;
    dataTable.psthSmoothed{g} = unit.psthSmoothed; 
    dataTable.testMetaData{g} = unit.testMetaData;                     % Stores Wilcox-Ranksum test performed on smoothed PSTH data
end

%% Save the table as a .mat file in the specified directory
save(fullfile(dataFolder, 'dataTable.mat'), 'dataTable');
end
