function [fullPSTH, binEdges, splitData] = generatePSTH(cellDataStruct)
    %% Generate PSTH for the entire recording
    %
    %   arg1
    %   arg2 
    %

    % Extract Unit Data
    unitData = cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0;
    disp('Extracted Unit Data:');  % Debugging statement
    disp(unitData);

    % Extract spiketimes for whole recording and normalize to sample rate
    spikeTimes = double(unitData.SpikeTimesall) / unitData.SamplingFrequency;

    % Debugging: Check spikeTimes
    disp('Spike Times (in seconds):');
    disp(spikeTimes);

    % Debugging: Ensure spiketimes array isn't empty
    if isempty(spikeTimes)
        warning('Spike times are empty! Check input data.');
    end

    % Set Binning
    recordingLength = unitData.RecordingDuration;  % Recording length in seconds
    binWidth = unitData.binWidth;  % Bin width in seconds

    % Debugging: Check the bin width and recording length
    fprintf('Bin width: %.2f s, Recording length: %.2f s\n', binWidth, recordingLength);

    % Check if bin width is valid
    if binWidth <= 0 || binWidth > recordingLength
        error('Invalid bin width! Bin width must be positive and less than recording length.');
    end

    % Calculate bin edges with helper function
    binEdges = edgeCalculator(0, binWidth, recordingLength);

    % Debugging: Check bin edges
    disp('Bin Edges:');
    disp(binEdges);

    % Ensure binEdges are not empty
    if isempty(binEdges)
        error('Bin edges are empty! Check edgeCalculator function.');
    end

    % Split Data
    numBins = length(binEdges) - 1;  % Number of bins
    fprintf('Number of bins: %d\n', numBins);  % Debugging statement

    splitData = cell(1, numBins);  % Preallocate cell array for bin data

    % Loop through bins and extract spikes for each bin
    for i = 1:numBins
        binStart = binEdges(i);
        binEnd = binEdges(i + 1);

        % Extract spikes within the current bin
        splitData{i} = spikeTimes(spikeTimes >= binStart & spikeTimes < binEnd);

        % Debugging: Print spikes in the current bin
        fprintf('Bin %2d | Start: %6.2f s | End: %6.2f s | Spikes: %3d\n', ...
            i, binStart, binEnd, length(splitData{i}));
    end

    % Calculate PSTH
    spikeCounts = cellfun(@length, splitData);  % Spike counts per bin
    fullPSTH = spikeCounts / binWidth;  % Convert to firing rate (spikes per second)

    % Debugging: Display spike counts and PSTH
    disp('Spike Counts per Bin:');
    disp(spikeCounts);
    disp('Full PSTH (spikes per second):');
    disp(fullPSTH);

    % Plot PSTH
    try
        plotPSTHRaw(binEdges, fullPSTH, 1860);  % Assuming plotPSTHRaw is available
    catch ME
        warning('Failed to plot PSTH: %s', ME.message);
    end

    % Save PSTH to struct
    try
        cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0.psthRaw = fullPSTH;
        disp('PSTH successfully saved to struct.');
    catch ME
        warning('Failed to save PSTH to struct: %s', ME.message);
    end

    % Debugging: Check data saved to struct
    disp('Updated Cell Data Struct:');
    disp(cellDataStruct.Pvalb.pvalb_hctztreat_0006_rec1.cid0);

end

%% Helper Function: Calculate Bin Edges
function edges = edgeCalculator(start, binWidth, stop)
    % Generate the leading edges for binning
    edges = start:binWidth:stop;  % Include stop value for the last bin edge
    
    % Debugging: Display generated edges
    disp('Generated Bin Edges in edgeCalculator:');
    disp(edges);
end

