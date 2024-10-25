%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROJECT FOLDER STRUCTURE AND SCRIPT FUNCTIONALITY:
%
% Starting with the following project folder structure:
%
% project_folder/
% ├─ SpikeStuff/                        % Main folder for all groups
% │  ├─ Group_1/                        % Group-level folder (e.g., Treatment 1)
% │  │  ├─ Recording_1/                 % Individual recording session
% │  │  │  ├─ Recording1.ns6            % Raw data file (e.g., neural data at 30 kHz)
% │  │  │  ├─ Recording1.nev            % Event markers (e.g., stim onsets, triggers)
% │  │  │  ├─ Recording1_timestamps.txt % Additional timestamp file (optional)
% │  │  │  ├─ Recording1.ccf            % Configuration or metadata file
% │  │  ├─ Recording_2/                 % Another recording session for Group 1
% │  │  ├─ Recording_N/                 % Additional recordings for Group 1
% │  ├─ Group_2/                        % Another experimental group (e.g., Control)
% │  │  ├─ Recording_1/
% │  │  ├─ Recording_2/
% ├─ LFP/ (Optional)                    % Optional folder for LFP data
%
% FUNCTIONALITY OF THIS SCRIPT:
% 1. **Group and Recording Traversal**:
%    - The script navigates through the `SpikeStuff/` folder, loading data from 
%      each group (e.g., Group_1, Group_2) and each recording within those groups.
%    - It processes raw neural data (`.ns6`) and extracts event markers (`.nev`).
%
% 2. **Data Extraction**:
%    - From each **recording folder**, the script loads:
%      - **Spike data**: Found in `.ns6` files (at 30 kHz).
%      - **Stimulation markers or events**: Extracted from `.nev` or `.txt` files.
%      - **Metadata/configuration**: Parsed from `.ccf` files or other metadata.
%
% 3. **Multi-Unit and Single-Unit Activity (MUA/SUA)**:
%    - If the recording contains SUA or MUA data (e.g., from Kilosort), 
%      this is handled and organized into MATLAB structures for analysis.
%
% 4. **Output**:
%    - Processed spike times, metadata, and analysis results are saved into 
%      structured MATLAB variables (`all_data`) and can be exported to `.mat` files.
%
% 5. **LFP Handling (Optional)**:
%    - If LFP data is present, it can be processed and saved from the `LFP/` folder.
%
% EXAMPLE WORKFLOW:
% - For each recording, the script:
%   1. Loads raw data from `.ns6` and `.nev` files.
%   2. Organizes spike times, events, and metadata into structured variables.
%   3. Saves the results into `all_data.mat` for further analysis or visualization.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



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

% Label responsive units and retrieve response types and unit IDs
data_table_FR = label_responsive_units_fun(all_data, {'RS', 'FS'}, binSize, moment, preTreatmentPeriod, postTreatmentPeriod);

% Extract response types and unit IDs from the data table
responseTypeVec = data_table_FR.ResponseType;
unitIDs = data_table_FR.UnitID;

% Generate PSTHs grouped by Recording Group > Response Type
generate_unit_PSTHs(all_data, binSize, smoothingWindow, ...
                    moment, preTreatmentPeriod, postTreatmentPeriod, ...
                    data_table_FR.ResponseType, data_table_FR.UnitID);

% Plot overlaid PSTHs for responsive vs. non-responsive units
plot_group_PSTH_fun(all_data);

% Plot mean + SEM PSTHs for all units (no overlaid individual PSTHs)
plot_mean_sem_PSTH_fun(all_data);

% Generate percent change PSTHs (mean + SEM)
percent_change_PSTH_fun(all_data);

% Generate ranked heatmap of modulated units
plot_heatmap_fun(all_data);
