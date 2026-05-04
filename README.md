# Deep Learning BLE Ranging

## Python Translation: `music_fb_alg.py`

The MUSIC distance estimation algorithm (`Residual Learning/music_fb_alg.m`) has been translated to Python as `music_fb_alg.py`. This enables use of the ranging algorithm in Python-based pipelines without requiring a MATLAB license.

### Usage

```python
import numpy as np
from music_fb_alg import music_fb_alg

# Parameters
M = 15          # Subarray size
nsig = 5        # Number of assumed signal sources
Nptot = 75      # Total number of subcarriers (len(CFR_data))
cal_dist = 0.0  # Calibration distance offset
threshold = -13 # Peak detection threshold in dB (relative to max)

# CFR_data: complex array of shape (Nptot,) or (Nptot, num_antennas)
# S:        steering matrix of shape (M, num_search_points)
# dists:    search distance vector of shape (num_search_points,)

dist_MUSIC, spec_dB, peakwidth = music_fb_alg(
    M, nsig, Nptot, dists, cal_dist, threshold, CFR_data, S
)
# dist_MUSIC: estimated distances, shape (nsig, 1), padded with NaN if fewer peaks found
# spec_dB:    MUSIC pseudo-spectrum in dB, shape (1, num_search_points)
# peakwidth:  width of the first (smallest delay) peak at half-prominence
```

The function signature and output semantics match the original MATLAB function. Multi-antenna input is supported by passing `CFR_data` as a 2D array with one column per antenna.

### Dependencies

```
numpy
scipy
```

Install via `uv sync` (uses `pyproject.toml`) or `pip install numpy scipy`.

### Running the Tests

```bash
uv run pytest tests/test_translation.py -v
```

Octave with the `signal` package is required for automatic baseline regeneration. If Octave is not available, the tests fall back to the last committed JSON baselines.

---

## Translation & Verification

The translation from MATLAB to Python was performed by AI with a line-by-line correspondence to the original `Residual Learning/music_fb_alg.m`. A multi-layer test strategy ensures correctness:

### 1. Octave-Generated Ground Truth

An Octave-compatible fork of the algorithm (`tests/music_fb_alg_octave.m`) is used to generate baseline input/output pairs across 6 parametrized test cases:

| Case                              | Description                                                          |
| --------------------------------- | -------------------------------------------------------------------- |
| `single_antenna_standard`         | Standard single-antenna, typical parameters                          |
| `multi_antenna_standard`          | 3-antenna input, different M/nsig                                    |
| `high_threshold_no_peaks`         | Threshold set so high that no peaks are found (fallback to `argmax`) |
| `multi_antenna_large_M`           | Large subarray size with 2 antennas                                  |
| `extreme_smoothing_L1`            | `Nptot == M`, so the smoothing window is a single frame              |
| `nsig_greater_than_peaks_padding` | Fewer peaks detected than `nsig`, testing NaN padding                |

The baselines are stored in `tests/test_data_multi.json` and automatically regenerated from Octave at test time. The Python output is compared against these baselines with tolerances of `rtol=1e-5, atol=1e-8`.

### 2. `findpeaks` Compatibility Layer

MATLAB's `findpeaks` (with `'SortStr','descend'`, `'MinPeakHeight'`, and `'WidthReference','halfprom'`) is not available in Octave. A custom `tests/findpeaks_compat.m` reimplements the required behavior (prominence calculation, half-prominence width via linear interpolation, descending sort). This wrapper is separately validated against SciPy's `scipy.signal.find_peaks` across 5 test signals to ensure cross-implementation consistency.

### 3. Channel Generator Cross-Validation

The channel response generator `gen_ch.m` was also translated to Python (`tests/gen_ch.py`). Its output is validated against Octave-generated baselines (`tests/gen_ch_data.json`) at high SNR (effectively noiseless) to confirm deterministic mathematical equivalence.

### 4. End-to-End Physics Simulation

Two end-to-end tests generate physically realistic BLE channel data for a known distance, run the full MUSIC pipeline, and verify the estimated distance matches the ground truth:

- **AWGN-only** (40 dB SNR, 15 m target): verifies core ranging accuracy
- **Rayleigh fading** (40 dB SNR, 12.5 m target): verifies robustness under severe multipath

### 5. Python-Native Edge Cases

Additional tests cover structural correctness without Octave:

- **Flat spectrum** (white noise input): no NaNs, correct output shapes
- **Zero signal**: division-by-zero protection works
- **Multi-antenna symmetry**: identical antenna columns produce identical results to single-antenna

### Differences from the MATLAB Original

The Python translation adds one defensive improvement not present in the original MATLAB code: a guard against division by zero in the spectrum denominator (`spec_den == 0` is clamped to machine epsilon). This prevents `Inf` values in degenerate inputs without affecting normal operation.

### Assessed Confidence: ~97%

The remaining uncertainty comes from:

- `findpeaks` behavioral edge cases not covered by the test scenarios (plateaus, tied heights)
- The ground truth baseline is Octave-adapted rather than from native MATLAB

## AI Disclaimer

Parts of this project were developed with the assistance of AI coding tools. Specifically, the Python translation of the MATLAB MUSIC algorithm (`music_fb_alg.py`), the channel generator (`tests/gen_ch.py`), and the associated test infrastructure were created using AI-assisted development. All generated code was reviewed and validated against the original MATLAB implementation through the multi-layer verification strategy described above.

## Original README

In this project, we examine the work of Zand et
al. [1] for high-accuracy ranging with Bluetooth Low Energy
(BLE). First, a frequency-hopping phase-based ranging solution
conforming to the BLE standard in the 2.4 GHz frequency band
is presented. Next, we investigate the impact of crystal offset
and phase-noise on the ranging accuracy. We extend the work in
[1] by mathematically examining the error introduced by device
mobility in BLE ranging and investigating a multi-path and
Rayleigh fading channel model. Further, we introduce a novel
residual learning technique for synthetically improving
signal-to-noise ratio (SNR) before ranging via subspace decomposition
methods (MUSIC). Our proposed deep neural network (DNN)
approach reduces localization error on both AWGN fixed fading
and AWGN Rayleigh fading channels in multi-path scenarios.
Simulation results for the various techniques and scenarios are
presented and discussed demonstrating the superior performance
of our novel methods.

[1] [A high-accuracy phase-based ranging solution with Bluetooth Low Energy (BLE)](https://ieeexplore.ieee.org/document/8904093)
