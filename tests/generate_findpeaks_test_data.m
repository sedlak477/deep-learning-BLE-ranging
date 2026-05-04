pkg load signal;

test_cases = {};

function tc = run_case(data, threshold, name)
    [pks, locs, widths, proms] = findpeaks_compat(data, 'MinPeakHeight', threshold);
    tc.name = name;
    tc.data = data;
    tc.threshold = threshold;
    tc.pks = pks;
    tc.locs = locs;
    tc.widths = widths;
    tc.proms = proms;
end

% Case 1: Simple Gaussian peaks (smooth, MUSIC-like)
x = linspace(0, 10, 100);
y1 = exp(-(x-3).^2 / 0.5) + 0.5*exp(-(x-7).^2 / 0.8);
tc1 = run_case(y1, 0.2, 'gaussian_peaks');
test_cases{end+1} = tc1;

% Case 2: Peaks on a slope (varying prominence)
y2 = y1 + 0.1*x;
tc2 = run_case(y2, 0.2, 'slope_peaks');
test_cases{end+1} = tc2;

% Case 3: Peaks close to boundary
y3 = zeros(1, 100); y3(3) = 10; y3(98) = 5; y3(50) = 8;
y3 = conv(y3, [0.1 0.2 0.4 0.2 0.1], 'same'); % smooth it
tc3 = run_case(y3, 0.1, 'boundary_close_peaks');
test_cases{end+1} = tc3;

% Case 4: No peaks (monotonic)
y4 = linspace(1, 10, 100);
tc4 = run_case(y4, 0, 'no_peaks');
test_cases{end+1} = tc4;

% Case 5: Many small peaks (noise-like)
rng(42);
y5 = rand(1, 100);
y5 = conv(y5, [0.3 0.4 0.3], 'same'); % smooth out to avoid completely erratic behavior
tc5 = run_case(y5, 0.5, 'noisy_peaks');
test_cases{end+1} = tc5;

fid = fopen('findpeaks_test_data.json', 'w');
fprintf(fid, '%s', jsonencode(test_cases));
fclose(fid);
disp('Successfully generated findpeaks_test_data.json');
exit(0);
