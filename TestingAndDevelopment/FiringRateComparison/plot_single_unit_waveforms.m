function plot_single_unit_waveforms(all_data, saveDirectory)
    % This function plots the individual waveforms and mean waveform for each unit.
    % Each unit's plot is saved to the specified directory.

    % Iterate through groups (e.g., 'Control', 'Emx', 'Pvalb')
    groupNames = fieldnames(all_data);
    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(all_data.(groupName));

        % Iterate through recordings within each group
        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(all_data.(groupName).(recordingName));

            % Iterate through units within each recording
            for u = 1:length(units)
                unitID = units{u};
                unitData = all_data.(groupName).(recordingName).(unitID);

                % Check if the required waveform data is available
                if ~isfield(unitData, 'SpikeTimes_all') || ...
                   ~isfield(unitData, 'Mean_Waveform')
                    warning('Skipping unit %s: Missing waveform data.', unitID);
                    continue;
                end

                % Extract waveforms and mean waveform
                spikeTimes = unitData.SpikeTimes_all;
                meanWaveform = unitData.Mean_Waveform;
                channel = unitData.Template_Channel;

                % Plot individual waveforms
                figure('Name', ['Waveforms - ', groupName, ' - ', unitID], 'NumberTitle', 'off');
                subplot(2, 1, 1);  % Top plot: Individual waveforms
                hold on;
                title(sprintf('Unit %s - %s', unitID, recordingName), 'Interpreter', 'none');
                xlabel('Time (samples)');
                ylabel('Voltage (uV)');

                % Plot individual waveforms (centered around spikes)
                for i = 1:length(spikeTimes)
                    if spikeTimes(i) > 20 && spikeTimes(i) < length(unitData.Vtrace) - 20
                        waveform = unitData.Vtrace(spikeTimes(i)-20:spikeTimes(i)+20);
                        plot(waveform, 'Color', [0.7, 0.7, 0.7]);  % Light gray for individual spikes
                    end
                end
                hold off;

                % Plot mean waveform
                subplot(2, 1, 2);  % Bottom plot: Mean waveform
                hold on;
                plot(meanWaveform, 'k', 'LineWidth', 2);  % Black line for mean waveform
                title('Mean Waveform');
                xlabel('Time (samples)');
                ylabel('Voltage (uV)');
                hold off;

                % Save the plot to the specified directory
                saveFileName = fullfile(saveDirectory, sprintf('%s_%s_%s_waveforms.png', groupName, recordingName, unitID));
                saveas(gcf, saveFileName);
                close(gcf);  % Close the figure after saving
            end
        end
    end
end
