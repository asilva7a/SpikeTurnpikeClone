function plotFlagOutliersInRecording(cellDataStruct, psthDataGroup, unitInfoGroup, groupIQRs)
    % Define custom colormaps for Emx and Pvalb groups
    emxColors = flipud(jet(128));  % Reds to yellows
    emxColors = emxColors(65:end, :);  % Select the warm half of jet colormap
    
    pvalbColors = parula(128);     % Blues to purples
    pvalbColors = pvalbColors(1:64, :);  % Select the cool half of parula colormap
    
    % Indices to track unique colors
    emxColorIndex = 1;
    pvalbColorIndex = 1;
    
    % Dictionary to store colors for each outlier
    outlierColors = containers.Map('KeyType', 'char', 'ValueType', 'any');
    
    % Loop through units in each group and assign colors to outliers
    for i = 1:length(cellDataStruct)
        % Adjust field names based on the actual structure
        unitID = cellDataStruct(i).UnitID;  % Replace with correct field name
        groupName = cellDataStruct(i).Group;  % Replace with correct field name
        responseType = cellDataStruct(i).Response;  % Replace with correct field name
        maxFiringRate = cellDataStruct(i).MaxRate;  % Replace with correct field name
        
        % Check if this unit is an outlier based on max firing rate and IQR thresholds
        iqrData = groupIQRs.(responseType).(groupName);
        upperFence = iqrData.upperFence;
        
        if maxFiringRate > upperFence  % If it's an outlier
            if strcmp(groupName, 'Emx')
                color = emxColors(emxColorIndex, :);  % Assign Emx color
                emxColorIndex = emxColorIndex + 1;
                if emxColorIndex > size(emxColors, 1)
                    emxColorIndex = 1;  % Wrap around if exceeding color array size
                end
            elseif strcmp(groupName, 'Pvalb')
                color = pvalbColors(pvalbColorIndex, :);  % Assign Pvalb color
                pvalbColorIndex = pvalbColorIndex + 1;
                if pvalbColorIndex > size(pvalbColors, 1)
                    pvalbColorIndex = 1;  % Wrap around if exceeding color array size
                end
            end
            % Store color for this outlier by unitID
            outlierColors(unitID) = color;
        end
    end
    
    % Plot the PSTHs for each response type and assign colors for outliers
    figure;
    tiledlayout(2, 3);
    
    responseTypes = {'Increased', 'Decreased', 'NoChange'};
    for rt = 1:length(responseTypes)
        responseType = responseTypes{rt};
        
        % Plot PSTHs
        ax1 = nexttile(rt);
        hold on;
        title(['Outliers - ', responseType, ' Units']);
        xlabel('Time (s)');
        ylabel('Firing Rate (spikes/s)');
        
        % Plot each unit's PSTH with color coding for outliers
        for i = 1:length(cellDataStruct)
            unitID = cellDataStruct(i).unitID;
            psth = psthDataGroup.(unitID);
            
            if isKey(outlierColors, unitID)
                color = outlierColors(unitID);  % Use outlier color if it exists
                plot(ax1, psth.time, psth.firingRate, 'Color', color, 'LineWidth', 1.5);
            else
                plot(ax1, psth.time, psth.firingRate, 'Color', [0.7 0.7 0.7]);  % Default color for non-outliers
            end
        end
        hold off;
        
        % Plot IQR scatter with custom colors for each group
        ax2 = nexttile(rt + 3);
        hold on;
        title(['IQR and Outliers - ', responseType]);
        xlabel('Groups');
        ylabel('Max Firing Rate (spikes/s)');
        
        % Plot IQR range as a shaded region
        for g = 1:length(fieldnames(groupIQRs.(responseType)))
            groupName = fieldnames(groupIQRs.(responseType));
            iqrData = groupIQRs.(responseType).(groupName{g});
            medianValue = iqrData.median;
            upperFence = iqrData.upperFence;
            lowerFence = iqrData.lowerFence;
            
            % Plot IQR as shaded area
            xRange = [g - 0.25, g + 0.25];
            fill(ax2, [xRange, fliplr(xRange)], [repmat(lowerFence, 1, 2), repmat(upperFence, 1, 2)], ...
                 [0.9 0.9 0.9], 'EdgeColor', 'none');  % Light gray IQR area
            plot(ax2, [g - 0.25, g + 0.25], [medianValue, medianValue], 'k--');  % Median line
        end
        
        % Plot each unit’s max firing rate, with unique colors for outliers
        for i = 1:length(cellDataStruct)
            unitID = cellDataStruct(i).unitID;
            groupName = cellDataStruct(i).groupName;
            maxFiringRate = cellDataStruct(i).maxFiringRate;
            
            if isKey(outlierColors, unitID)
                color = outlierColors(unitID);  % Use outlier color
                gIndex = find(strcmp(fieldnames(groupIQRs.(responseType)), groupName));
                scatter(ax2, gIndex, maxFiringRate, 36, 'MarkerFaceColor', color, 'MarkerEdgeColor', 'k');
            end
        end
        hold off;
        set(ax2, 'XTick', 1:length(fieldnames(groupIQRs.(responseType))), 'XTickLabel', fieldnames(groupIQRs.(responseType)));
    end
end
