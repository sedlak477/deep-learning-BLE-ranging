import numpy as np

def gen_ch(num_runs, SNR, dist_vec, att_vec, n, delta_f, c, rayleigh=False):
    """
    Generate two-way channel response (IQ samples) in AWGN or Rayleigh fading with AWGN.
    Translated from MATLAB gen_ch.m
    
    Args:
        num_runs: int, number of trials
        SNR: float, signal to noise ratio in dB
        dist_vec: array of distances (paths)
        att_vec: array of attenuations
        n: array of subcarrier indices
        delta_f: float, measurement spacing in frequency
        c: float, propagation speed
        rayleigh: bool, whether to use Rayleigh fading
        
    Returns:
        CFR_data_array: complex ndarray of shape (len(n), num_runs)
    """
    npaths = len(dist_vec)
    Nptot = len(n)
    
    CFR_data_array = np.zeros((Nptot, num_runs), dtype=complex)
    
    dist_vec = np.asarray(dist_vec)
    if not rayleigh:
        att_vec = np.asarray(att_vec)
    n = np.asarray(n).reshape(-1, 1)
    
    for k in range(num_runs):
        if rayleigh:
            att_vec = np.random.randn(npaths) + 1j * np.random.randn(npaths)
            
        channel_comb_i = np.zeros((Nptot, 1), dtype=complex)
        channel_comb_r = np.zeros((Nptot, 1), dtype=complex)
        
        for i in range(npaths):
            ch_i = att_vec[i] * np.exp(-1j * (2 * np.pi * delta_f * (dist_vec[i] / c) * n))
            ch_r = att_vec[i] * np.exp(-1j * (2 * np.pi * delta_f * (dist_vec[i] / c) * n))
            
            channel_comb_i += ch_i
            channel_comb_r += ch_r
            
        Eave = np.mean([
            (1.0 / Nptot) * np.sum(np.abs(channel_comb_i)**2),
            (1.0 / Nptot) * np.sum(np.abs(channel_comb_r)**2)
        ])
        
        noise_i = np.sqrt(10**(-SNR/10) * 0.5 * Eave) * (np.random.randn(Nptot, 1) + 1j * np.random.randn(Nptot, 1))
        channel_comb_rx_1 = channel_comb_i + noise_i
        
        noise_r = np.sqrt(10**(-SNR/10) * 0.5 * Eave) * (np.random.randn(Nptot, 1) + 1j * np.random.randn(Nptot, 1))
        channel_comb_rx_2 = channel_comb_r + noise_r
        
        CFR_data_array[:, k] = (channel_comb_rx_1 * channel_comb_rx_2).flatten()
        
    return CFR_data_array
