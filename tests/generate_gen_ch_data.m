addpath('../Residual Learning');

% Test case for gen_ch without random noise or Rayleigh (SNR = 300)
num_runs = 2;
SNR = 300; % Basically no noise
dist_vec = [15.0; 25.0];
att_vec = [1.0, 0.5];
n = (-37:37).';
delta_f = 1e6;
c = 3e8;
rayleigh = false;

% Run MATLAB's gen_ch
CFR_data_array = gen_ch(num_runs, SNR, dist_vec, att_vec, n, delta_f, c, rayleigh);

% Create data to export
output_data = struct();
output_data.inputs.num_runs = num_runs;
output_data.inputs.SNR = SNR;
output_data.inputs.dist_vec = dist_vec;
output_data.inputs.att_vec = att_vec;
output_data.inputs.n = n;
output_data.inputs.delta_f = delta_f;
output_data.inputs.c = c;
output_data.inputs.rayleigh = rayleigh;

output_data.CFR_data_array_real = real(CFR_data_array);
output_data.CFR_data_array_imag = imag(CFR_data_array);

fid = fopen('gen_ch_data.json', 'w');
json_str = jsonencode(output_data);
fprintf(fid, '%s', json_str);
fclose(fid);
disp('Successfully generated gen_ch_data.json');
exit(0);
