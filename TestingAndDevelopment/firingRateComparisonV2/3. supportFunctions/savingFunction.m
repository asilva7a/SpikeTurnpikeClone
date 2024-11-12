% Save figure to the specified directory with error handling
function saveFigureWithRetry(fig, saveDir, fileName)
    if ~isfolder(saveDir)
        mkdir(saveDir);
    end
    
    % Full path for the figure
    fullPath = fullfile(saveDir, fileName);
    maxAttempts = 3;
    attempt = 1;
    success = false;
    
    while ~success && attempt <= maxAttempts
        try
            % Try different save methods in order
            switch attempt
                case 1
                    % Method 1: Standard save
                    saveas(fig, fullPath);
                case 2
                    % Method 2: Export graphics
                    exportgraphics(fig, strrep(fullPath, '.fig', '.png'), 'Resolution', 300);
                    exportgraphics(fig, strrep(fullPath, '.fig', '.pdf'), 'ContentType', 'vector');
                case 3
                    % Method 3: Print to file
                    print(fig, fullPath, '-dpdf', '-vector');
                    print(fig, strrep(fullPath, '.fig', '.png'), '-dpng', '-r300');
            end
            success = true;
            fprintf('Figure saved successfully to: %s (Method %d)\n', fullPath, attempt);
            
        catch ME
            % Log the error
            fprintf('Save attempt %d failed:\n', attempt);
            fprintf('Error Message: %s\n', ME.message);
            fprintf('Error Identifier: %s\n', ME.identifier);
            
            % Clean up potentially corrupt file
            if exist(fullPath, 'file')
                delete(fullPath);
                fprintf('Removed potentially corrupt file.\n');
            end
            
            % Wait briefly before next attempt
            pause(1);
            attempt = attempt + 1;
            
            % If all attempts failed, try alternative location
            if attempt > maxAttempts
                try
                    % Try saving to temporary directory
                    tempDir = tempdir;
                    tempPath = fullfile(tempDir, fileName);
                    saveas(fig, tempPath);
                    fprintf('Figure saved to temporary location: %s\n', tempPath);
                    success = true;
                catch ME2
                    fprintf('Failed to save to temporary location:\n%s\n', ME2.message);
                end
            end
        end
    end
    
    % Close figure if successful
    if success
        try
            close(fig);
        catch
            fprintf('Warning: Could not close figure handle.\n');
        end
    else
        warning('Failed to save figure after all attempts.');
    end
end

 
