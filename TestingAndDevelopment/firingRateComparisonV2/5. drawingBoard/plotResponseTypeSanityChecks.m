function plotResponseTypeSanityChecks(cellDataStruct, figureFolder)
    % plotResponseTypeSanityChecks: Creates summary plots for each group/recording.
    %
    % Inputs:
    %   - cellDataStruct: Data structure containing response types and metrics.
    %   - figureFolder: Path to the folder where figures will be saved.
    
    % Check if figureFolder exists, create if not
    if ~isfolder(figureFolder)
        try
            mkdir(figureFolder);
            fprintf('Created figure folder: %s\n', figureFolder);
        catch ME
            error('Error creating figure folder: %s\n%s', figureFolder, ME.message);
        end
    end
    
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
                
                try
                    unitData = cellDataStruct.(groupName).(recordingName).(unitID);

                    % Retrieve metrics for plotting
                    preRates(u) = unitData.testMetaData.MeanPre;
                    postRates(u) = unitData.testMetaData.MeanPost;
                    responseTypes{u} = unitData.responseType;

                catch ME
                    % Catch any errors related to accessing unit data
                    warning('Error processing unit %s in %s - %s: %s', unitID, groupName, recordingName, ME.message);
                    responseTypes{u} = 'Data Missing';
                    continue;
                end
            end

            % Define color coding for response types
            colors = cellfun(@(x) getColorByResponseType(x), responseTypes, 'UniformOutput', false);

            try
                % Create ladder plot for pre- and post-treatment firing rates
                f = figure('Visible', 'off');  % Set 'Visible' to 'off' to avoid displaying during processing
                hold on;
                for u = 1:numel(units)
                    if ~isnan(preRates(u)) && ~isnan(postRates(u))
                        plot([1, 2], [preRates(u), postRates(u)], '-o', 'Color', colors{u}, 'LineWidth', 1.5);
                    end
                end
                xticks([1 2]);
                xticklabels({'Pre-Treatment', 'Post-Treatment'});
                ylabel('Firing Rate (spikes/s)');
                title(sprintf('Ladder Plot of Firing Rates\n%s - %s', groupName, recordingName));
                legend({'Increased', 'Decreased', 'No Change'}, 'Location', 'Best');
                hold off;

                % Save figure
                savePath = fullfile(figureFolder, sprintf('%s_%s_FiringRateLadderPlot.png', groupName, recordingName));
                saveas(f, savePath);
                fprintf('Saved figure: %s\n', savePath);
                close(f);  % Close figure to free up memory

            catch ME
                % Catch any errors related to plotting or saving figures
                warning('Error creating or saving figure for %s - %s: %s', groupName, recordingName, ME.message);
            end
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
