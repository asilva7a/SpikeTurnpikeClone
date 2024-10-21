% Create a synthetic data structure to match your original example
all_data.Control.pvalb_notreat_0005_rec1.cid28 = struct();

% Set synthetic fields with test values
all_data.Control.pvalb_notreat_0005_rec1.cid28.Sampling_Frequency = 30000;  % 30 kHz
all_data.Control.pvalb_notreat_0005_rec1.cid28.Recording_Duration = [1800, 1800];  % 30 minutes each (before & after stim)

% Generate synthetic spike times (baseline: 5 Hz, stim: 10 Hz)
fs = all_data.Control.pvalb_notreat_0005_rec1.cid28.Sampling_Frequency;
duration_baseline = all_data.Control.pvalb_notreat_0005_rec1.cid28.Recording_Duration(1);  % seconds
duration_stim = all_data.Control.pvalb_notreat_0005_rec1.cid28.Recording_Duration(2);  % seconds

% Calculate expected spike counts
num_spikes_baseline = 5 * duration_baseline;  % 5 Hz * 1800 sec
num_spikes_stim = 10 * duration_stim;  % 10 Hz * 1800 sec

% Generate random spike times within their respective durations (in seconds)
baseline_spike_times_sec = sort(rand(num_spikes_baseline, 1) * duration_baseline);
stim_spike_times_sec = sort(rand(num_spikes_stim, 1) * duration_stim) + duration_baseline;

% Convert spike times to samples
baseline_spike_times_samples = round(baseline_spike_times_sec * fs);
stim_spike_times_samples = round(stim_spike_times_sec * fs);

% Combine all spike times into SpikeTimes_all
all_data.Control.pvalb_notreat_0005_rec1.cid28.SpikeTimes_all = [baseline_spike_times_samples; stim_spike_times_samples];
all_data.Control.pvalb_notreat_0005_rec1.cid28.SpikeTimes_baseline = baseline_spike_times_samples;
all_data.Control.pvalb_notreat_0005_rec1.cid28.SpikeTimes_stim = stim_spike_times_samples;

% Initialize firing rate fields (empty for testing script updates)
all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_baseline = [];
all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_stim = [];
all_data.Control.pvalb_notreat_0005_rec1.cid28.MeanFR_total = [];

% Populate other fields with placeholder values
all_data.Control.pvalb_notreat_0005_rec1.cid28.Amplitude = 1.0;
all_data.Control.pvalb_notreat_0005_rec1.cid28.Cell_Type = 'PV+';
all_data.Control.pvalb_notreat_0005_rec1.cid28.PeakEvokedFR = 15.0;  % Example value
all_data.Control.pvalb_notreat_0005_rec1.cid28.FirstSpikeLatency = 0.05;  % Example latency in seconds

% Display confirmation
disp('Synthetic data struct created.');
