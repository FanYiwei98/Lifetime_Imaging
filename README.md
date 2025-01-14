# Lifetime_Imaging
MATLAB algorithm of lifetime imaging

# MATLAB Lifetime Imaging and Analysis

This MATLAB script is designed for lifetime imaging analysis of time-series luminescence data. It processes a sequence of TIFF images, performs noise filtering, selects Regions of Interest (ROI), and computes the lifetime of the luminescence signal using different fitting methods. The output includes a lifetime map, statistical analysis of the lifetime distribution, and an interactive plot for data exploration.

## Features
- **Noise Filtering**: Removes pixels with intensity below a user-defined threshold.
- **Region of Interest (ROI)**: Allows the user to select a specific region for analysis or use the full image.
- **Lifetime Calculation**: Supports linear fitting and single exponential fitting with offset to calculate the lifetime.
- **Post-processing**: Filters out unrealistic lifetime values based on user-defined limits.
- **Interactive Visualization**: Displays the lifetime map and allows interaction to show lifetime values at specific points.
- **Lifetime Distribution**: Computes and visualizes the statistical distribution of lifetime values.

## Requirements
- MATLAB (R2020 or newer recommended)
- Image Processing Toolbox (for image loading and manipulation)
- Curve Fitting Toolbox (for nonlinear fitting)

## Installation
1. Download or clone the repository to your local machine.
2. Place your TIFF images in a directory.
3. Run the script in MATLAB.

## Usage
### Step 1: Input Parameters
The script will prompt the user to input:
- **Noise Threshold**: Intensity threshold below which the pixel value will be set to 0 (filtered out).
- **Time Step**: The time step between consecutive images (in arbitrary units).

### Step 2: Load TIFF Files
- The script will ask the user to select a folder containing the TIFF files. It will automatically sort the files by numeric order in the filename.

### Step 3: Select ROI or Full Image
- The user will be prompted to choose either:
  - **ROI**: Manually select a region of interest for analysis.
  - **Full**: Use the entire image for analysis.

### Step 4: Choose Fitting Method
- The user can select between:
  - **Linear Fit**: Lifetime is calculated based on a linear fit of the intensity decay.
  - **Single Exponential Fit (with Offset)**: Lifetime is calculated based on a single exponential decay model with an offset.

### Step 5: Lifetime Calculation
- The script calculates the lifetime using the selected fitting method and generates a lifetime map.

### Step 6: Post-processing
- The lifetime values are post-processed to remove values that are either negative or exceed a threshold of 1000.

### Step 7: Display Results
- A lifetime map is displayed using a colormap.
- The user can interact with the lifetime map and see the lifetime values at specific points.
- The script computes and displays the average lifetime, standard deviation, and time step.
- A histogram of the lifetime distribution is shown.

## Functions
### `loadFiles(file_pattern)`
Prompts the user to select a directory and loads files matching the specified pattern (e.g., `*.tif`).

### `sortFilesByNumber(file_list)`
Sorts the list of files by numeric order in the filename.

### `loadTiffImagesSequentially(file_list, folder_path)`
Loads TIFF images from the specified folder and stores them in a cell array.

### `selectROI(image)`
Allows the user to interactively select an ROI on the provided image using MATLAB's `imrect` tool.

### `calculateLifetimeLinear(intensity_matrix, tt)`
Performs a linear fit to calculate the lifetime for each pixel in the intensity matrix.

### `calculateLifetimeExponentialWithOffset(intensity_matrix, tt)`
Performs a single exponential fit with offset to calculate the lifetime for each pixel.

### `postProcessLifetime(tau)`
Post-processes the lifetime matrix by removing values that are negative or exceed 1000.

### `displayResults(tau, tt)`
Displays the lifetime map, lifetime distribution histogram, and lifetime statistics. Provides interactive data cursor functionality for exploring the results.

### `displayLifetimeValue(~, event, tau)`
Callback function for the data cursor, displaying the lifetime value at the cursor position in the lifetime map.

## Example Workflow
1. Run the script.
2. Input the noise threshold and time step.
3. Select the folder containing your TIFF images.
4. Choose the ROI or full image mode.
5. Select the fitting method (linear or exponential).
6. View the lifetime map and interact with it to display lifetime values at specific points.
7. Analyze the lifetime distribution using the histogram.

## Dependencies
- **Image Processing Toolbox**: For image loading and manipulation.
- **Curve Fitting Toolbox**: For nonlinear fitting (e.g., exponential fitting).

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
