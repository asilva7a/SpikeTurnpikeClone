function mainPlotFunction(dataStruct)
    % Main function to create combined figure with subplots

    figure;
    t = tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact'); % Adjust as needed

    % Create each subplot using separate functions
    ax1 = nexttile(t);
    plot1 = plotFirstSubplot(ax1, dataStruct); % Call subplot function 1

    ax2 = nexttile(t);
    plot2 = plotSecondSubplot(ax2, dataStruct); % Call subplot function 2

    ax3 = nexttile(t);
    plot3 = plotThirdSubplot(ax3, dataStruct); % Call subplot function 3

    % Additional formatting or combined annotations can go here
    title(t, 'Combined Figure with Subplots');
end

function ax = plotFirstSubplot(ax, dataStruct)
    % Function to plot first subplot
    axes(ax); % Use specified axis
    plot(dataStruct.time, dataStruct.variable1, 'b');
    title('Subplot 1');
    xlabel('Time (s)');
    ylabel('Variable 1');
end

function ax = plotSecondSubplot(ax, dataStruct)
    % Function to plot second subplot
    axes(ax);
    plot(dataStruct.time, dataStruct.variable2, 'r');
    title('Subplot 2');
    xlabel('Time (s)');
    ylabel('Variable 2');
end

function ax = plotThirdSubplot(ax, dataStruct)
    % Function to plot third subplot
    axes(ax);
    plot(dataStruct.time, dataStruct.variable3, 'g');
    title('Subplot 3');
    xlabel('Time (s)');
    ylabel('Variable 3');
end
