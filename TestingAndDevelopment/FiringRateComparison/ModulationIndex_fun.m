% Access the individual unit struct
unit = all_data.Emx.emx_hctztreat_0001_rec1.cid546;

% Extract sampling frequency (in Hz)
fs = unit.Sampling_Frequency;

%% User input or default values for baseline/stim durations
defaultStimTimeSec = 1860;  % Default: 31 minutes
defaultBaselineSec = 1800;  % Default: 30 minutes
defaultStimSec = 1800;      % Default: 30 minutes

% Get user input (or use default if input is empty)
stimTimeSec = input(sprintf('Enter time of stim (default = %d sec): ', defaultStimTimeSec));
if isempty(stimTimeSec), stimTimeSec = defaultStimTimeSec; end

baselineSec = input(sprintf('Enter duration before stim (default = %d sec): ', defaultBaselineSec));
if isempty(baselineSec), baselineSec = defaultBaselineSec; end

stimDurationSec = input(sprintf('Enter duration after stim (default = %d sec): ', defaultStimSec));
if isempty(stimDurationSec), stimDurationSec = defaultStimSec; end

% Convert stimulation time and durations to samples
stimTimeSample = round(stimTimeSec * fs);
baselineSamples = round(baselineSec * fs);
stimSamples = round(stimDurationSec * fs);

% DEBUG: Print key values to verify window ranges
fprintf('Stimulation Time: %d samples\n', stimTimeSample);
fprintf('Baseline Window: %d to %d samples\n', stimTimeSample - baselineSamples, stimTimeSample);
fprintf('Stim Window: %d to %d samples\n', stimTimeSample, stimTimeSample + stimSamples);

%% Filter spike times for baseline and stim periods
spikeTimesBaseline = unit.SpikeTimes_all(unit.SpikeTimes_all >= (stimTimeSample - baselineSamples) ...
                                         & unit.SpikeTimes_all < stimTimeSample);

spikeTimesStim = unit.SpikeTimes_all(unit.SpikeTimes_all >= stimTimeSample ...
                                     & unit.SpikeTimes_all < (stimTimeSample + stimSamples));

% DEBUG: Print filtered spike times
disp('Spike Times (Baseline):');
disp(spikeTimesBaseline);
disp('Spike Times (Stim):');
disp(spikeTimesStim);

%% Calculate the number of spikes
numSpikesBaseline = length(spikeTimesBaseline);
numSpikesStim = length(spikeTimesStim);

% DEBUG: Print number of spikes for verification
fprintf('Number of Baseline Spikes: %d\n', numSpikesBaseline);
fprintf('Number of Stim Spikes: %d\n', numSpikesStim);

%% Calculate total spikes and durations
totalSpikes = numSpikesBaseline + numSpikesStim;
totalDuration = baselineSec + stimDurationSec;

%% Calculate the firing rates
MeanFR_baseline = numSpikesBaseline / baselineSec;
MeanFR_stim = numSpikesStim / stimDurationSec;
MeanFR_total = totalSpikes / totalDuration;

%% Update specific fields in the original struct
all_data.Emx.emx_hctztreat_0001_rec1.cid546.MeanFR_baseline = MeanFR_baseline;
all_data.Emx.emx_hctztreat_0001_rec1.cid546.MeanFR_stim = MeanFR_stim;
all_data.Emx.emx_hctztreat_0001_rec1.cid546.MeanFR_total = MeanFR_total;

%% Display the calculated firing rates
fprintf('Baseline Firing Rate: %.2f Hz\n', MeanFR_baseline);
fprintf('Stim Firing Rate: %.2f Hz\n', MeanFR_stim);
fprintf('Total Firing Rate: %.2f Hz\n', MeanFR_total);

%% Store Results in a Struct for Saving
results = struct();
results.MeanFR_baseline = MeanFR_baseline;
results.MeanFR_stim = MeanFR_stim;
results.MeanFR_total = MeanFR_total;
results.numSpikesBaseline = numSpikesBaseline;
results.numSpikesStim = numSpikesStim;
results.totalSpikes = totalSpikes;

%% Save Results to MAT File
save('modulation_results.mat', 'results');

%% Write Results to CSV File
% Convert struct to table for easy CSV writing
resultsTable = struct2table(results);

% Write to CSV
writetable(resultsTable, 'modulation_results.csv');

%% Display a Confirmation
disp('Results saved to modulation_results.mat and modulation_results.csv');
