import numpy as np
import scipy.linalg
import scipy.signal

def music_fb_alg(M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S):
    """
    MUSIC distance estimation algorithm with forward-backward averaging.
    Translated from MATLAB music_fb_alg.m
    """
    CFR_data = np.asarray(CFR_data)
    if CFR_data.ndim == 1:
        CFR_data = CFR_data.reshape(-1, 1)
        
    num_ant = CFR_data.shape[1]
    
    if num_ant > 1:
        # Combining across antenna measurements
        L = Nptot - M + 1
        Rn = np.zeros((Nptot, Nptot), dtype=complex)
        for k in range(num_ant):
            col = CFR_data[:, k].reshape(-1, 1)
            Rn = col @ col.conj().T + Rn
        Rn = Rn / num_ant
        
        # Smoothing
        RSM = np.zeros((M, M), dtype=complex)
        for k in range(L):
            RSM = RSM + Rn[k:k+M, k:k+M]
        RSM = RSM / L
    else:
        # Smoothing Method for single antenna
        L = Nptot - M + 1
        RSM = np.zeros((M, M), dtype=complex)
        # CFR_data is shape (Nptot, 1)
        cfr_1d = CFR_data[:, 0]
        for i in range(L):
            subArray = cfr_1d[i:i+M].reshape(-1, 1)
            RSM = subArray @ subArray.conj().T + RSM
        RSM = RSM / L

    J = np.fliplr(np.eye(M))
    R = (RSM + J @ RSM.conj() @ J) / 2  # Forward-backward averaging

    # Compute the eigenvectors and eigenvalues
    # svd in scipy returns U, s, Vh
    U, s, Vh = scipy.linalg.svd(R)
    eigenvals = np.real(s)
    eigenvects = U
    
    # Sort eigenvectors (svd already sorts by descending singular values, but let's be explicit)
    sort_idx = np.argsort(eigenvals)[::-1]
    eigenvals = eigenvals[sort_idx]
    eigenvects = eigenvects[:, sort_idx]

    # Get the noise eigenvectors
    noise_eigenvects = eigenvects[:, nsig:]

    # Compute MUSIC spectrum
    # S is shape (M, num_dists)
    # spec_dens = abs((S'*noise_eigenvects)).^2;
    S_conj_T = S.conj().T  # shape: (num_dists, M)
    spec_dens = np.abs(S_conj_T @ noise_eigenvects) ** 2
    spec_den = np.sum(spec_dens, axis=1)
    
    # Avoid divide by zero
    # NOTE: Original MATLAB code does not protect against division by zero here,
    # which can result in Inf values. We clamp to eps as a defensive improvement.
    spec_den[spec_den == 0] = np.finfo(float).eps
    
    spec = 1.0 / spec_den
    spec_dB = 10 * np.log10(spec)

    # Define peak threshold
    spec_T = np.max(spec) * (10 ** (threshold / 10.0))

    # Find Delays from the peaks of the spectrum
    # MATLAB: findpeaks(spec, 'SortStr', 'descend', 'MinPeakHeight', spec_T, 'WidthReference', 'halfprom')
    peaks, properties = scipy.signal.find_peaks(spec, height=spec_T, rel_height=0.5, width=0)
    
    if len(peaks) == 0:
        locs = np.array([np.argmax(spec)])
        peakwidth = np.inf
    else:
        # Sort by peak magnitude descending ('SortStr','descend')
        peak_heights = properties['peak_heights']
        sort_desc = np.argsort(peak_heights)[::-1]
        peaks = peaks[sort_desc]
        widths = properties['widths'][sort_desc]
        
        # Incase we don't detect at least nsig peaks
        locs_check = min(nsig, len(peaks))
        
        locs_subset = peaks[:locs_check]
        widths_subset = widths[:locs_check]
        
        # Sorted by smallest to largest delay ('ascend')
        sort_ind = np.argsort(locs_subset)
        locs = locs_subset[sort_ind]
        widths_sorted = widths_subset[sort_ind]
        
        peakwidth = widths_sorted[0]
        
    # Calculate distance
    # locs in MATLAB are 1-indexed, in Python 0-indexed.
    # dists should be indexed by locs
    dists = np.asarray(dists).flatten()
    dist_MUSIC = dists[locs] - cal_dist

    # Include this so that the plot title doesn't give an error if we only calculate one path.
    if len(dist_MUSIC) < nsig and nsig > 1:
        padding = np.full(nsig - len(dist_MUSIC), np.nan)
        dist_MUSIC = np.concatenate((dist_MUSIC, padding))

    # reshape to match MATLAB's column vector output if needed
    dist_MUSIC = dist_MUSIC.reshape(-1, 1)
    
    # In MATLAB spec_dB is a row vector
    spec_dB = spec_dB.reshape(1, -1)

    return dist_MUSIC, spec_dB, peakwidth
