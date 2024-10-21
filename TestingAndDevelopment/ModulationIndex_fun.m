% Access the individual unit struct
unit = all_data.Emx.emx_hctztreat_0001_rec1.cid546;  % Do not overwrite this struct

% Extract sampling frequency (in Hz)
fs = unit.Sampling_Frequency;

%% User input or default values for baseline/stim durations
defaultBaselineSec = 1800;  % Default: 30 minutes
defaultStimSec = 1800;      % Default: 30 minutes

% Get user input (or use default if input is empty)
stimTimeSec = input('Enter the stimulation time (in seconds): ');
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

%% Update firing rate fields only, without overwriting the struct
if isempty(unit.MeanFR_baseline) && baselineSec > 0
    all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_baseline = numSpikesBaseline / baselineSec;
end

if isempty(unit.MeanFR_stim) && stimDurationSec > 0
    all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_stim = numSpikesStim / stimDurationSec;
end

if isempty(unit.MeanFR_total) && totalDuration > 0
    all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_total = totalSpikes / totalDuration;
end

%% Display the calculated firing rates
fprintf('Baseline Firing Rate: %.2f Hz\n', all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_baseline);
fprintf('Stim Firing Rate: %.2f Hz\n', all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_stim);
fprintf('Total Firing Rate: %.2f Hz\n', all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_total);
