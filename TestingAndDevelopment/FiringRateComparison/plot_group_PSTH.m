function plot_group_PSTH(all_data)
    % Plot overlaid PSTHs for responsive and non-responsive units.
    
    % Assuming all_data is a struct with fields 'responsive' and 'non_responsive'
    % Each field contains an array of PSTH data for the respective units
    
    % Extract PSTH data
    responsive_data = all_data.responsive;
    non_responsive_data = all_data.non_responsive;
    
    % Define time vector (assuming PSTH data is aligned to a common time base)
    time_vector = -100:100; % Example time vector, adjust as needed
    
    % Plot responsive units
    figure;
    subplot(2, 1, 1);
    hold on;
    for i = 1:length(responsive_data)
        plot(time_vector, responsive_data{i}, 'b');
    end
    title('Responsive Units');
    xlabel('Time (ms)');
    ylabel('Firing Rate (Hz)');
    hold off;
    
    % Plot non-responsive units
    subplot(2, 1, 2);
    hold on;
    for i = 1:length(non_responsive_data)
        plot(time_vector, non_responsive_data{i}, 'r');
    end
    title('Non-Responsive Units');
    xlabel('Time (ms)');
    ylabel('Firing Rate (Hz)');
    hold off;
end
