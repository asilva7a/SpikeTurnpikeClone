function plot_unit_PSTH_fun(psthData)
    groups = fieldnames(psthData);
    for g = 1:length(groups)
        groupName = groups{g};
        units = fieldnames(psthData.(groupName));
        
        figure('Name', ['PSTHs - ', groupName], 'NumberTitle', 'off');
        hold on;
        
        for u = 1:length(units)
            unit = units{u};
            psth = psthData.(groupName).(unit).PSTH;
            responseType = psthData.(groupName).(unit).ResponseType;

            % Define color based on response type
            color = getColorForResponseType(responseType);
            
            % Plot the PSTH
            plot(psth, 'Color', color, 'LineWidth', 1.5);
        end
        hold off;
    end
end

function color = getColorForResponseType(responseType)
    switch responseType
        case 'Increased'
            color = [1, 0, 0];  % Red
        case 'Decreased'
            color = [0, 0, 1];  % Blue
        otherwise
            color = [0, 0, 0];  % Black
    end
end
