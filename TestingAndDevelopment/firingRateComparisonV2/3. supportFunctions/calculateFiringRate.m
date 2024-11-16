function [cellDataStruct] = calculateFiringRate(cellDataStruct, paths, params, varargin)
    % Parse input parameters
    p = inputParser;
    
    % Required inputs
    addRequired(p, 'cellDataStruct', @isstruct);
    addRequired(p, 'paths', @isstruct);
    addRequired(p, 'params', @isstruct);
    
    % Optional parameters with defaults
    addParameter(p, 'preWindow', 1859, @isnumeric);
    addParameter(p, 'postWindow', 3540, @isnumeric);
    addParameter(p, 'verbose', true, @islogical);
    
    % Parse inputs
    parse(p, cellDataStruct, paths, params, varargin{:});
    opts = p.Results;
    
    % Extract parameters
    treatmentTime = params.treatmentTime;
    preWindow = opts.preWindow;
    postWindow = opts.postWindow;
    
    if opts.verbose
        fprintf('Calculating firing rates:\n');
        fprintf('Treatment time: %d seconds\n', treatmentTime);
        fprintf('Pre-treatment window: %d seconds\n', preWindow);
        fprintf('Post-treatment window: %d seconds\n', postWindow);
    end

    % Loop to determine total units (unchanged)
    totalUnits = 0;
    groupNames = fieldnames(cellDataStruct);
    for g = 1:length(groupNames)
        recordings = fieldnames(cellDataStruct.(groupNames{g}));
        for r = 1:length(recordings)
            units = fieldnames(cellDataStruct.(groupNames{g}).(recordings{r}));
            totalUnits = totalUnits + numel(units);
        end
    end

    % Preallocate arrays
    preRates = NaN(totalUnits, 1);
    postRates = NaN(totalUnits, 1);
    unitIndex = 0;

    % Main processing loop
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                try
                    % Extract unit data
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                    if opts.verbose
                        fprintf('Processing: Group: %s | Recording: %s | Unit: %s\n', ...
                            groupName, recordingName, unitID);
                    end

                    % Validate required fields
                    if ~isfield(unitData, 'psthSmoothed') || ~isfield(unitData, 'binWidth')
                        warning('Skipping Unit %s: Missing psthSmoothed or binWidth.', unitID);
                        continue;
                    end

                    % Process unit
                    unitIndex = unitIndex + 1;
                    psthData = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;

                    % Calculate time vector
                    numBins = numel(psthData);
                    timeVector = (0:numBins - 1) * binWidth;

                    % Define windows
                    preTreatmentStart = max(0, treatmentTime - preWindow);
                    preTreatmentEnd = treatmentTime;
                    postTreatmentStart = treatmentTime;
                    postTreatmentEnd = treatmentTime + postWindow;

                    % Find indices
                    preIndices = timeVector >= preTreatmentStart & timeVector < preTreatmentEnd;
                    postIndices = timeVector >= postTreatmentStart & timeVector < postTreatmentEnd;

                    % Calculate rates
                    preTreatmentRate = mean(psthData(preIndices), 'omitnan');
                    postTreatmentRate = mean(psthData(postIndices), 'omitnan');

                    % Store results
                    preRates(unitIndex) = preTreatmentRate;
                    postRates(unitIndex) = postTreatmentRate;
                    cellDataStruct.(groupName).(recordingName).(unitID).frBaselineAvg = preTreatmentRate;
                    cellDataStruct.(groupName).(recordingName).(unitID).frTreatmentAvg = postTreatmentRate;
                    
                catch ME
                    fprintf('Error processing unit %s in %s/%s: %s\n', ...
                        unitID, groupName, recordingName, ME.message);
                end
            end
        end
    end
    
    % Save intermediate results
    if isfield(paths, 'frTreatmentDir')
        saveFile = fullfile(paths.frTreatmentDir, 'data', ...
            sprintf('firingRates_%s.mat', char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm'))));
        save(saveFile, 'preRates', 'postRates');
        if opts.verbose
            fprintf('Saved firing rates to: %s\n', saveFile);
        end
    end
end
