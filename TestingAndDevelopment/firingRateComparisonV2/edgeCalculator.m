function edges = edgeCalculator(start, binWidth, stop)
    % calculateEdges: Generates leading edges for histogram bins
    % Inputs:
    %   start     - Start of the binning range
    %   binWidth  - Width of each bin
    %   stop      - End of the binning range
    % Output:
    %   edges     - Vector of leading edges for the bins

    % Calculate edges
    edges = start:binWidth:stop - 1;  % Generate leading edges
end
