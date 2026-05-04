function [pks, locs, widths, proms] = findpeaks_compat(data, varargin)
% FINDPEAKS_COMPAT  Octave-compatible wrapper replicating MATLAB's findpeaks
% with 'SortStr','descend', 'MinPeakHeight', and 'WidthReference','halfprom'.
%
% [pks, locs, widths, proms] = findpeaks_compat(data, 'MinPeakHeight', threshold)
%
% Returns peaks sorted by descending height, with half-prominence widths.

    % Parse MinPeakHeight from varargin
    min_height = -Inf;
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'MinPeakHeight')
            min_height = varargin{i+1};
        end
    end

    % Step 1: Find peaks using Octave's findpeaks (basic)
    [pks, locs] = findpeaks(data, 'MinPeakHeight', min_height);

    if isempty(pks)
        widths = [];
        proms = [];
        return;
    end

    % Step 2: Compute prominences
    % Prominence = peak height minus the highest valley on the more
    % constraining side (the higher of the two minimum-valleys found
    % by descending left and right to a higher peak or signal boundary).
    n = length(data);
    num_peaks = length(pks);
    proms = zeros(size(pks));

    for i = 1:num_peaks
        pk_idx = locs(i);
        pk_val = pks(i);

        % Search left: find the minimum between this peak and the nearest
        % higher peak (or signal boundary) to the left
        left_min = pk_val;
        for j = pk_idx-1:-1:1
            if data(j) > pk_val
                break;
            end
            left_min = min(left_min, data(j));
        end

        % Search right: same logic
        right_min = pk_val;
        for j = pk_idx+1:n
            if data(j) > pk_val
                break;
            end
            right_min = min(right_min, data(j));
        end

        % Prominence is the peak height minus the higher of the two valleys
        ref_level = max(left_min, right_min);
        proms(i) = pk_val - ref_level;
    end

    % Step 3: Compute half-prominence widths
    % Width is measured at: h_eval = peak_height - 0.5 * prominence
    % Find where the signal crosses h_eval on both sides, using
    % linear interpolation (matching MATLAB/SciPy behavior).
    widths = zeros(size(pks));

    for i = 1:num_peaks
        pk_idx = locs(i);
        h_eval = pks(i) - 0.5 * proms(i);

        % Find left crossing point (interpolated)
        left_ip = 1;  % default: signal boundary
        for j = pk_idx-1:-1:1
            if data(j) <= h_eval
                % Linear interpolation between j and j+1
                left_ip = j + (h_eval - data(j)) / (data(j+1) - data(j));
                break;
            end
        end

        % Find right crossing point (interpolated)
        right_ip = n;  % default: signal boundary
        for j = pk_idx+1:n
            if data(j) <= h_eval
                % Linear interpolation between j-1 and j
                right_ip = j - 1 + (h_eval - data(j-1)) / (data(j) - data(j-1));
                break;
            end
        end

        widths(i) = right_ip - left_ip;
    end

    % Step 4: Sort by descending peak height ('SortStr','descend')
    [pks, sort_idx] = sort(pks, 'descend');
    locs = locs(sort_idx);
    widths = widths(sort_idx);
    proms = proms(sort_idx);
end
