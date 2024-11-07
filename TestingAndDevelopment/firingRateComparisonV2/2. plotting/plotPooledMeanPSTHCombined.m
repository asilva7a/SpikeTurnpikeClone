function plotPooledMeanPSTH(cellDataStruct, figureFolder, treatmentTime, plotType, unitFilter)
    % plotPooledMeanPSTH: Plots pooled mean PSTH data for 'Emx' and 'Pvalb' groups.
    % 
    % Inputs:
    %   - cellDataStruct: Data structure with unit data.
    %   - figureFolder: Directory to save the plots.
    %   - treatmentTime: Time (s) where treatment was administered.
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')
    %   - unitFilter: Specifies which units to include ('single', 'multi', or 'both').

    % Colors for each response type
    colors = struct('Increased', [1, 0, 0, 0.3], 'Decreased', [0, 0, 1, 0.3], 'NoChange', [0.5, 0.5, 0.5, 0.3]);

    % Gather data across response types
    increasedPSTHs = [];
    decreasedPSTHs = [];
    noChangePSTHs = [];
    timeVector = [];

    experimentGroups = {'Emx', 'Pvalb'};
    for g = 1:length(experimentGroups)
        groupName = experimentGroups{g};
        if ~isfield(cellDataStruct, groupName)
            continue;
        end
        recordings = fieldnames(cellDataStruct.(groupName));

        for r = 1:length(recordings)
            recordingName = recordings{r};
            units = fieldnames(cellDataStruct.(groupName).(recordingName));

            for u = 1:length(units)
                unitID = units{u};
                unitData = cellDataStruct.(groupName).(recordingName).(unitID);
                isSingleUnit = isfield(unitData, 'IsSingleUnit') && unitData.IsSingleUnit == 1;
                if (strcmp(unitFilter, 'single') && ~isSingleUnit) || (strcmp(unitFilter, 'multi') && isSingleUnit)
                    continue;
                end

                if isfield(unitData, 'psthSmoothed') && isfield(unitData, 'responseType')
                    psth = unitData.psthSmoothed;
                    binWidth = unitData.binWidth;
                    binEdges = unitData.binEdges;
                    timeVector = binEdges(1:end-1) + binWidth / 2; % Bin centers

                    switch unitData.responseType
                        case 'Increased'
                            increasedPSTHs = [increasedPSTHs; psth];
                        case 'Decreased'
                            decreasedPSTHs = [decreasedPSTHs; psth];
                        case 'No Change'
                            noChangePSTHs = [noChangePSTHs; psth];
                    end
                end
            end
        end
    end

    % Plotting logic
    figure('Position', [100, 100, 1600, 500]);
    sgtitle(sprintf('Pooled Experimental Units (Emx + Pvalb) - %s', plotType));

    % Plot each response type
    plotSubplot(timeVector, increasedPSTHs, colors.Increased, 'Increased', treatmentTime, plotType, 1);
    plotSubplot(timeVector, decreasedPSTHs, colors.Decreased, 'Decreased', treatmentTime, plotType, 2);
    plotSubplot(timeVector, noChangePSTHs, colors.NoChange, 'No Change', treatmentTime, plotType, 3);

    % Save figure
    saveDir = fullfile(figureFolder, 'PooledSmoothedPSTHs');
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    fileName = sprintf('Pooled_Emx_Pvalb_%s_smoothedPSTH_%s.fig', plotType, unitFilter);
    saveas(gcf, fullfile(saveDir, fileName));
    fprintf('Figure saved to: %s\n', fullfile(saveDir, fileName));
    close(gcf);
end

function plotSubplot(timeVector, psths, color, titleText, treatmentTime, plotType, subplotIndex)
    subplot(1, 3, subplotIndex);
    if ~isempty(psths)
        meanPSTH = mean(psths, 1, 'omitnan');
        semPSTH = std(psths, 0, 1, 'omitnan') / sqrt(size(psths, 1));
        plotPSTHWithOverlaySubplot(timeVector, meanPSTH, semPSTH, psths, color, titleText, treatmentTime, plotType);
    else
        title([titleText ' (No Data)']);
    end
end

%% Helper Function: Plot PSTH with Overlay in a Subplot using shadedErrorBar or individual traces
function plotPSTHWithOverlaySubplot(timeVector, meanPSTH, semPSTH, individualPSTHs, color, plotTitle, treatmentTime, plotType)
    % plotPSTHWithOverlaySubplot: Helper function to plot mean PSTH with SEM or individual traces.
    %
    % Inputs:
    %   - timeVector: Vector of time points for the PSTH
    %   - meanPSTH, semPSTH: Mean and SEM of the PSTH
    %   - individualPSTHs: Matrix of individual PSTHs for the current response type
    %   - color: Color for both individual traces and mean PSTH line
    %   - plotTitle: Title for the subplot
    %   - treatmentTime: Time in seconds for the vertical line
    %   - plotType: Type of plot ('mean+sem' or 'mean+individual')

    hold on;

    if strcmp(plotType, 'mean+sem')
        % Plot mean PSTH with SEM using shadedErrorBar, using the color of the response type
        shadedErrorBar(timeVector, meanPSTH, semPSTH, 'lineprops', {'Color', color(1:3), 'LineWidth', 2});
    elseif strcmp(plotType, 'mean+individual')
        % Plot individual PSTHs with color and transparency
        for i = 1:size(individualPSTHs, 1)
            plot(timeVector, individualPSTHs(i, :), 'Color', [color(1:3), color(4)], 'LineWidth', 0.5);
        end
        % Plot mean PSTH on top with the same color as individual traces
        plot(timeVector, meanPSTH, 'Color', color(1:3), 'LineWidth', 2);
    else
        error("plotType must be either 'mean+sem' or 'mean+individual'");
    end

    % Plot treatment line
    xline(treatmentTime, '--', 'Color', [0, 1, 0], 'LineWidth', 1.5);

    % Labels, title, and limits
    xlabel('Time (s)');
    ylabel('Firing Rate (spikes/s)');
    title(plotTitle);
    
    % Set axis limits
    ylim([0 inf]);  % Set y-axis lower limit to 0 and let the upper limit auto-adjust
    xlim([0 5400]); % Set x-axis upper limit to 5400 seconds

    hold off;
end





