function plotExampleTraces(all_data)
    % This function loads and plots example voltage traces and spike waveforms
    % from wildtype, sham, and treated experimental groups.

    % Plot Wildtype Example Unit
    plotUnitTrace(all_data.Wildtype.wt_exp1.cid706, ...
        '/home/cresp1el-local/Documents/MATLAB/hd_project_sinda/hd_project_sinda/SpikeStuff/Wildtype/wt_exp1/exp1_wt_1726001.ns6', ...
        30000, [300 6000]);

    % Plot Sham Example Unit
    plotUnitTrace([], ...
        '/home/cresp1el-local/Documents/MATLAB/hd_project_sinda/hd_project_sinda/SpikeStuff/Sham/sham_exp1_1/exp1_hd_sham_1709001.ns6', ...
        30000, [300 6000], 'c:29');

    % Plot Treated Example Unit
    plotUnitTrace([], ...
        '/home/cresp1el-local/Documents/MATLAB/hd_project_sinda/hd_project_sinda/SpikeStuff/Treated/treated_exp4/exp4_hd_treated_1759001.ns6', ...
        30000, [300 6000], 'c:14');
end

function plotUnitTrace(unitData, nsxFilePath, samplingFreq, bandpassRange, channel)
    % Helper function to plot voltage traces and spike waveforms for a given unit.
    % Inputs:
    % - unitData: Struct containing unit-specific data (optional, can be empty)
    % - nsxFilePath: Path to the NSx file containing voltage data
    % - samplingFreq: Sampling frequency in Hz
    % - bandpassRange: Frequency range for bandpass filtering [low, high]
    % - channel: (Optional) Specific channel to load from the NSx file

    if nargin < 5  % If no channel provided, use the unit's template channel
        channel = strcat('c:', num2str(unitData.Template_Channel));
    end

    % Load NSx file
    NSx = openNSx(nsxFilePath, 'read', channel, 'uV', 'precision', 'double');
    vtrace = NSx.Data;

    % Apply bandpass filter to the voltage trace
    vtrace = bandpass(vtrace, bandpassRange, samplingFreq);

    % Plot spike waveforms if spike times are available
    if ~isempty(unitData)
        spikeTimes_samples = unitData.SpikeTimes_all;
        figure;
        hold on;
        for spike_ind = 1:length(spikeTimes_samples)
            t_spike = spikeTimes_samples(spike_ind);
            wf = vtrace(1, t_spike-20:t_spike+20);
            plot(wf);  % Plot waveform for each spike
        end
        hold off;

        % Restrict spikes to the 1000-1010 second window
        spikeTimes_samples = spikeTimes_samples((spikeTimes_samples >= 1000*samplingFreq) & ...
                                                (spikeTimes_samples <= 1010*samplingFreq));

        % Plot the voltage trace within the restricted window
        figure;
        plot(0:(1/samplingFreq):10, vtrace(1000*samplingFreq:1010*samplingFreq));
        hold on;

        % Overlay red boxes for detected spikes
        for spike_ind = 1:length(spikeTimes_samples)
            t_spike = spikeTimes_samples(spike_ind);
            t_spike_relative = (t_spike - 1000*samplingFreq) / samplingFreq;
            yl = ylim;  % Get y-axis limits
            xl = xlim;  % Get x-axis limits

            % Define the red box around the spike
            xBox = [t_spike_relative-(20/samplingFreq), t_spike_relative+(20/samplingFreq), ...
                    t_spike_relative+(20/samplingFreq), t_spike_relative-(20/samplingFreq)];
            yBox = [yl(1), yl(1), yl(2), yl(2)];
            patch(xBox, yBox, 'red', 'FaceAlpha', 0.1);  % Draw the patch
        end
        hold off;
    end
end

