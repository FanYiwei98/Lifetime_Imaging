clear all;
clc;

% Custom input for noise and step size
prompt = {'Enter noise information:', 'Enter stepwise:'};
dlgtitle = 'Input parameters';
dims = [1 35];
definput = {'300', '30'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

% Parameter parsing
noise = str2double(answer{1}); % Noise threshold
tt = str2double(answer{2});    % Time step

% Select TIFF folder and load files
[file_list, folder_path] = loadFiles('*.tif*'); % Load TIFF files
file_list = sortFilesByNumber(file_list);       % Sort files by numeric order
images = loadTiffImagesSequentially(file_list, folder_path); % Load images sequentially

% Image dimensions
num_files = numel(images);
[height, width] = size(images{1});
intensity_matrix = zeros(num_files, height, width);

% Fill the intensity matrix and perform noise filtering
for k = 1:num_files
    img = images{k};
    img(img < noise) = 0; % Set pixels below the noise threshold to 0
    intensity_matrix(k, :, :) = img;
end

% Select ROI region
choice = questdlg('Please select the area mode for calculation', 'Area mode selection', 'ROI', 'Full', 'ROI');
switch(choice)
    case 'ROI'
        rect_pos = selectROI(images{1}); % Manually select ROI
    case 'Full'
        rect_pos = [1, 1, width, height]; % Use the full image
    otherwise
        disp('No ROI mode selected');
        return;
end

% Crop the intensity matrix
rect_x = rect_pos(1);
rect_y = rect_pos(2);
rect_width = rect_pos(3);
rect_height = rect_pos(4);

intensity_matrix = intensity_matrix(:, rect_y:(rect_y+rect_height-1), rect_x:(rect_x+rect_width-1));

% Select fitting method
fit_method = questdlg('Please select the fitting method', 'Fitting Method', ...
    'Linear Fit', 'Single Exponential Fit (with Offset)', 'Linear Fit');

% Calculate lifetime
if strcmp(fit_method, 'Linear Fit')
    tau = calculateLifetimeLinear(intensity_matrix, tt);
elseif strcmp(fit_method, 'Single Exponential Fit (with Offset)')
    tau = calculateLifetimeExponentialWithOffset(intensity_matrix, tt);
else
    disp('No fitting method selected');
    return;
end

% Post-processing and visualization of lifetime
tau = postProcessLifetime(tau);
displayResults(tau, tt);

% --- Function Definitions ---

% Load file list
function [file_list, folder_path] = loadFiles(file_pattern)
    folder_path = uigetdir();
    file_list = dir(fullfile(folder_path, file_pattern));
end

% Sort files by numeric order
function sorted_files = sortFilesByNumber(file_list)
    filenames = {file_list.name};
    file_numbers = regexp(filenames, '\d+', 'match');
    file_numbers = cellfun(@(x) str2double(x{end}), file_numbers);
    [~, sorted_indices] = sort(file_numbers);
    sorted_files = file_list(sorted_indices);
end

% Load TIFF files sequentially and name them
function images = loadTiffImagesSequentially(file_list, folder_path)
    num_files = numel(file_list);
    images = cell(1, num_files);
    for i = 1:num_files
        images{i} = imread(fullfile(folder_path, file_list(i).name));
    end
end

% Select ROI region
function rect_pos = selectROI(image)
    imshow(image, []);
    rect = imrect;
    rect_pos = round(getPosition(rect));
    hold on;
    rectangle('Position', rect_pos, 'EdgeColor', 'r', 'LineWidth', 2);
    hold off;
end

% Linear fit to calculate lifetime matrix
function tau = calculateLifetimeLinear(intensity_matrix, tt)
    [num_files, rect_height, rect_width] = size(intensity_matrix);
    tau = zeros(rect_height, rect_width);
    t = (0:num_files-1)' * tt;
    tic;
    for i = 1:rect_height
        for j = 1:rect_width
            I = squeeze(intensity_matrix(:, i, j));
            valid_indices = I > 0;
            if sum(valid_indices) < 2
                tau(i, j) = 0;
                continue;
            end
            I = log(I(valid_indices));
            t_valid = t(valid_indices);
            coefficients = polyfit(t_valid, I, 1);
            b = coefficients(1);
            yFit = polyval(coefficients, t_valid);
            rSquared = 1 - sum((I - yFit).^2) / sum((I - mean(I)).^2);
            if rSquared > 0.96 && b ~= 0
                tau(i, j) = -1 ./ b;
            else
                tau(i, j) = 0;
            end
        end
    end
    elapsed_time = toc;
    disp(['Fitting and processing time: ', num2str(elapsed_time), 's']);
end

% Single exponential fit with offset to calculate lifetime matrix
function tau = calculateLifetimeExponentialWithOffset(intensity_matrix, tt)
    [num_files, rect_height, rect_width] = size(intensity_matrix);
    tau = zeros(rect_height, rect_width);
    t = (0:num_files-1)' * tt; % Time vector
    tic;

    % Parallel computation optimization
    parfor i = 1:rect_height
        for j = 1:rect_width
            I = squeeze(intensity_matrix(:, i, j)); % Extract pixel time series
            valid_indices = I > 0; % Remove intensity values <= 0
            if sum(valid_indices) < 2 % Skip if insufficient data points
                tau(i, j) = 0;
                continue;
            end
            I_valid = I(valid_indices);
            t_valid = t(valid_indices);

            % Define fitting model and parameter options
            fit_options = fitoptions('Method', 'NonlinearLeastSquares', ...
                'StartPoint', [max(I_valid), 10, min(I_valid)], ...
                'Lower', [0, 0, -Inf], ...
                'Upper', [Inf, Inf, Inf]);
            fit_type = fittype('a*exp(-t/b) + c', 'independent', 't', ...
                'coefficients', {'a', 'b', 'c'}, 'options', fit_options);
            try
                % Perform fitting
                fit_result = fit(t_valid, I_valid, fit_type);
                % Calculate fit results and fit quality
                yFit = feval(fit_result, t_valid);
                ss_total = sum((I_valid - mean(I_valid)).^2);
                ss_residual = sum((I_valid - yFit).^2);
                rSquared = 1 - (ss_residual / ss_total);

                % Extract time constant
                b = fit_result.b;
                if rSquared > 0.95 && b > 0
                    tau(i, j) = b;
                else
                    tau(i, j) = 0;
                end
            catch
                % If fitting fails, set time constant to 0
                tau(i, j) = 0;
            end
        end
    end

    elapsed_time = toc;
    disp(['Fitting and processing time: ', num2str(elapsed_time), 's']);
end


% Lifetime post-processing
function tau = postProcessLifetime(tau)
    tau(tau < 10) = 0;
    tau(tau > 1000) = 0;
    % tau = localConsistencyCheck(tau, 20, 60);
end

% Display results
function displayResults(tau, tt)
    % Display lifetime image
    figure;
    imshow(tau, 'DisplayRange', [100, 600]); % Display lifetime image
    colormap('turbo'); % Use turbo colormap
    colorbar; % Add color bar
    title('Lifetime Map');

    % Mouse pointer interaction function
    dcm = datacursormode(gcf); % Enable data cursor mode
    datacursormode on; % Turn on data cursor
    set(dcm, 'UpdateFcn', @(obj, event) displayLifetimeValue(obj, event, tau));
    
    % Calculate and display lifetime distribution statistics
    nz = nonzeros(tau); % Extract non-zero lifetime values
    avg = mean(nz); % Average lifetime
    stddev = std(nz); % Standard deviation
    disp(['Standard deviation: ', num2str(stddev)]);
    disp(['Average lifetime: ', num2str(avg)]);
    disp(['Time Step: ', num2str(tt)]);
    
    % Plot lifetime distribution histogram
    figure;
    edges = linspace(round(min(nz)) - 1, round(max(nz)) + 1, 100);
    histogram(nz, edges);
    title('Lifetime Distribution');
end

% Data cursor callback function: Display lifetime value at cursor position
function txt = displayLifetimeValue(~, event, tau)
    % Get the x, y coordinates of the cursor
    pos = event.Position; % [x, y]
    x = round(pos(1));
    y = round(pos(2));
    
    % Get the corresponding lifetime value
    if x > 0 && y > 0 && x <= size(tau, 2) && y <= size(tau, 1)
        lifetime_value = tau(y, x); % Note MATLAB's (y, x) indexing order
    else
        lifetime_value = NaN; % Return NaN if out of bounds
    end
    
    % Display lifetime value
    if isnan(lifetime_value) || lifetime_value == 0
        txt = {['X: ', num2str(x)], ['Y: ', num2str(y)], 'Lifetime: Invalid'};
    else
        txt = {['X: ', num2str(x)], ['Y: ', num2str(y)], ['Lifetime: ', num2str(lifetime_value)]};
    end
end
