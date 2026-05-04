pkg load signal;
addpath('../Residual Learning');

test_cases = {};

% Helper function to create test case struct
function tc = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, name)
    try
        [dist_MUSIC, spec_dB, peakwidth] = music_fb_alg_octave(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S);
        
        tc.name = name;
        tc.inputs.M = M;
        tc.inputs.nsig = nsig;
        tc.inputs.Nptot = Nptot;
        tc.inputs.dists = dists;
        tc.inputs.cal_dist = cal_dist;
        tc.inputs.threshold = threshold;
        tc.inputs.S_real = real(S);
        tc.inputs.S_imag = imag(S);
        tc.inputs.CFR_data_real = real(CFR_data);
        tc.inputs.CFR_data_imag = imag(CFR_data);
        
        tc.outputs.dist_MUSIC = dist_MUSIC;
        tc.outputs.spec_dB = spec_dB;
        tc.outputs.peakwidth = peakwidth;
    catch e
        disp(['Failed on ' name ': ' e.message]);
        tc = [];
    end
end

% Base parameters
dists = linspace(0, 10, 100).';
cal_dist = 0.5;

% Case 1: Standard single antenna
M = 5; nsig = 2; Nptot = 10; threshold = -10;
rng(42); S = exp(1j * rand(M, 100)); CFR_data = rand(Nptot, 1) + 1j * rand(Nptot, 1);
tc1 = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, 'single_antenna_standard');
if ~isempty(tc1), test_cases{end+1} = tc1; end

% Case 2: Multi-antenna
M = 4; nsig = 3; Nptot = 12; threshold = -15;
rng(43); S = exp(1j * rand(M, 100)); CFR_data = rand(Nptot, 3) + 1j * rand(Nptot, 3);
tc2 = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, 'multi_antenna_standard');
if ~isempty(tc2), test_cases{end+1} = tc2; end

% Case 3: High threshold (few/no peaks)
M = 6; nsig = 1; Nptot = 15; threshold = 50; % High threshold
rng(44); S = exp(1j * rand(M, 100)); CFR_data = rand(Nptot, 1) + 1j * rand(Nptot, 1);
tc3 = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, 'high_threshold_no_peaks');
if ~isempty(tc3), test_cases{end+1} = tc3; end

% Case 4: Different M and nsig combinations
M = 8; nsig = 4; Nptot = 20; threshold = -5;
rng(45); S = exp(1j * rand(M, 100)); CFR_data = rand(Nptot, 2) + 1j * rand(Nptot, 2);
tc4 = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, 'multi_antenna_large_M');
if ~isempty(tc4), test_cases{end+1} = tc4; end

% Case 5: Nptot == M (Extreme smoothing limit, L=1)
M = 10; nsig = 2; Nptot = 10; threshold = -10;
rng(46); S = exp(1j * rand(M, 100)); CFR_data = rand(Nptot, 1) + 1j * rand(Nptot, 1);
tc5 = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, 'extreme_smoothing_L1');
if ~isempty(tc5), test_cases{end+1} = tc5; end

% Case 6: nsig > found_peaks (Padding with NaN check)
M = 5; nsig = 4; Nptot = 10; threshold = 5; % High threshold so maybe 1 or 2 peaks found, but we want nsig=4
rng(47); S = exp(1j * rand(M, 100)); CFR_data = rand(Nptot, 1) + 1j * rand(Nptot, 1);
tc6 = run_case(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S, 'nsig_greater_than_peaks_padding');
if ~isempty(tc6), test_cases{end+1} = tc6; end

% Write all test cases to JSON
fid = fopen('test_data_multi.json', 'w');
json_str = jsonencode(test_cases);
fprintf(fid, '%s', json_str);
fclose(fid);
disp('Successfully generated test_data_multi.json');
exit(0);
