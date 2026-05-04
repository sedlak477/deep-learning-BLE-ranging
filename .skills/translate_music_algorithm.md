# Agent SKILL: Translate Forward-Backward MUSIC Algorithm to Python

This artifact contains the necessary instructions (SKILLs) and framework to completely automate the translation of the `music_fb_alg.m` MATLAB function into Python and verify its absolute correctness.

## Resources and Tools Created
To aid in this task, the following tools and scripts have been created in the `tests/` directory of the workspace:
1. **`tests/test_translation.py`**: An extensive Pytest suite that loads expected MATLAB inputs and outputs from a JSON file and runs the translated Python code to verify correctness within tight floating-point tolerances.
2. **`tests/generate_test_data.m`**: An Octave/MATLAB script that generates random complex inputs, calls the original `music_fb_alg.m`, and saves the state to `tests/test_data.json`.
3. **`.skills/read_pdf_skill.py`**: A python tool that AI agents can use to extract text from the theoretical PDFs (e.g. `read_pdf("Deep Learning BLE Ranging - Report.pdf")`).

## Step-by-Step Instructions for the Agent

### Step 1: Read the Theoretical Details
Before starting the translation, you should understand the theory behind the MUSIC algorithm in this specific context.
- Use the `read_pdf` skill to read the presentation and report PDFs located in the root directory.

### Step 2: Generate the Ground-Truth Test Data
To ensure absolute correctness, we must generate reference outputs using the original MATLAB code.
- If a real MATLAB installation is available, run `tests/generate_test_data.m` in MATLAB.
- **Note on Octave**: Octave's `findpeaks` function in the `signal` package does not support MATLAB's `SortStr` or `WidthReference` parameters. If you must use Octave to generate the data, you will need to either write a wrapper for `findpeaks` or temporarily adjust `music_fb_alg.m` to generate the test data, then revert it. 

### Step 3: Translate `music_fb_alg.m` to Python
Create a Python file `music_fb_alg.py` in the root directory. Translate the function carefully:
- **Multiple Antennas**: `music_fb_alg` handles combining correlation matrices across multiple antennas.
- **Covariance Matrix**: Ensure you accurately replicate the forward-backward averaging (`J = fliplr(eye(M))`, `R = (RSM+J*conj(RSM)*J)/2`).
- **SVD**: Use `scipy.linalg.svd` or `numpy.linalg.svd`. Note the difference in return formats compared to MATLAB.
- **Spectrum Computation**: Replicate the matrix multiplications carefully.
- **Find Peaks**: Use `scipy.signal.find_peaks`. You will need to map MATLAB's `SortStr='descend'` and `WidthReference='halfprom'` to their SciPy equivalents. This is the most complex part of the translation. Ensure you accurately capture the peak locations and widths.

### Step 4: Run the Automated Test Suite
- Ensure `pytest`, `numpy`, and `scipy` are installed (`uv add pytest numpy scipy`).
- Run the test suite: `pytest tests/test_translation.py`
- Iterate on your Python translation until all assertions in the test suite pass with the required tolerances.
