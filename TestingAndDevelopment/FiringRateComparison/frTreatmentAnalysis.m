% analyze_units.m
% Main script to organize analysis, plotting, and statistical tests.

% Load the data
load('all_data.mat');  % Load your structured data

% Define analysis parameters
binSize = 0.1;  % 100ms bins for PSTH
smoothingWindow = [1 1 1 1 1];  % Light smoothing window
moment = 1860;  % Reference event (e.g., stimulus onset)
preTreatmentPeriod = 1800;  % Seconds before the event
postTreatmentPeriod = 1800;  % Seconds after the event

% Generate and plot individual PSTHs for all units
generate_PSTH(all_data, binSize, smoothingWindow, moment, preTreatmentPeriod, postTreatmentPeriod);

% Plot overlaid PSTHs for responsive vs. non-responsive units
plot_group_PSTH(all_data);

% Plot mean + SEM PSTHs for all units (no overlaid individual PSTHs)
plot_mean_sem_PSTH(all_data);

% Generate percent change PSTHs (mean + SEM)
percent_change_PSTH(all_data);

% Generate ranked heatmap of modulated units
plot_heatmap(all_data);
