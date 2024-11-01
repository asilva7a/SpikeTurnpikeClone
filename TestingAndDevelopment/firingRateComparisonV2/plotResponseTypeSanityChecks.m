function plotResponseTypeSanityChecks(cellDataStruct, figureFolder)
    % plotResponseTypeSanityChecks: Creates summary plots for each group/recording.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing response types and metrics.
    %   - figureFolder: Path to the folder where figures will be saved.
    
    % Loop over groups and recordings to plot each set separately
    groupNames = fieldnames(cellDataStruct);

    for g = 1:length(groupNames)
        groupName = groupNames{g};
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));
            
            % Initialize arrays for plotting
            preRates = NaN(1, numel(units));
            postRates = NaN(1, numel(units));
            responseTypes = cell(1, numel(units));
            
            for u = 1:numel(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                % Retrieve metrics for plotting
                preRates(u) = unitData.testMetaData.MeanPre;
                postRates(u) = unitData.testMetaData.MeanPost;
                responseTypes{u} = unitData.responseType;
            end

            % Define color coding for response types
            colors = cellfun(@(x) getColorByResponseType(x), responseTypes, 'UniformOutput', false);

            % Create ladder plot for pre- and post-treatment firing rates
            figure;
            hold on;
            for u = 1:numel(units)
                plot([1, 2], [preRates(u), postRates(u)], '-o', 'Color', colors{u}, 'LineWidth', 1.5);
            end
            xticks([1 2]);
            xticklabels({'Pre-Treatment', 'Post-Treatment'});
            ylabel('Firing Rate (spikes/s)');
            title(sprintf('Ladder Plot of Firing Rates\n%s - %s', groupName, recordingName));
            legend({'Increased', 'Decreased', 'No Change'}, 'Location', 'Best');
            hold off;

            % Save figure
            saveas(gcf, fullfile(figureFolder, sprintf('%s_%s_FiringRateLadderPlot.png', groupName, recordingName)));
            close(gcf);  % Close figure to free up memory
        end
    end
end

%% Helper Function: Get Color by Response Type
function color = getColorByResponseType(responseType)
    % Returns color based on response type
    switch responseType
        case 'Increased'
            color = [1, 0, 0]; % Red
        case 'Decreased'
            color = [0, 0, 1]; % Blue
        case 'No Change'
            color = [0.5, 0.5, 0.5]; % Gray
        otherwise
            color = [0, 0, 0]; % Black for unspecified or 'Data Missing'
    end
end
