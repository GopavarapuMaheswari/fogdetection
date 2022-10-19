%%
close all
clear
clc
addpath(genpath(pwd))

%% Basic Parameters
ReadPath = './examples';
name = 'example02.png';  % example01 - example05

% RealSense parameters, used for computing disparity
Baseline = 55.0871;
Focallength = 1367.6650;

%% Read Data and Preprocess
I1 = imread(fullfile(ReadPath, 'rgb', name));
I1=imresize(I1,[720,1280]);
[I]=Bounding_function(I1,4);%%%dehazing
figure;
subplot(121);
imshow(I1)
title('input')
subplot(122);
imshow(I)
title('dehazed')

distance = double(imread(fullfile(ReadPath, 'depth_u16', name)));
distance(distance > 10000) = 0;     % do not consider the pixels with distances over 10m (RealSense depth range)
disparity = Focallength * Baseline ./ distance;

rgb = preprocess_input(I);
disparity = preprocess_input(disparity);
disparity(isinf(disparity)) = 0;
disparity = round(disparity);

disp('Successfully read data.');

%% Compute V-disparity
% v-disparity
m = size(disparity, 1);
n = max(max(disparity)) + 1;
vdis = zeros(m, n);
for i = 1 : m
    for j = 1 : n
        vdis(i, j) = length(find(disparity(i, :) == (j - 1)));
    end
end

% steerable filter
theta = [0, 45, 90];
vdisSteerable = zeros(size(vdis, 1), size(vdis, 2), 3); % use steerable filter in 3 directions
for i = 1 : length(theta)
    vdisSteerable(:, :, i) = steerGaussFilterOrder2(vdis, theta(i), 3);
end

% select the pixels that have much difference between 3 directions
vdisSteerableDiff = zeros(size(vdis));
for i = 1 : size(vdisSteerable, 1)
    for j = 1 : size(vdisSteerable, 2)
        vdisSteerableDiff(i, j) = max(vdisSteerable(i, j, :)) - min(vdisSteerable(i, j, :));
    end
end
vdisFilter = zeros(size(vdis));
vdisFilterThresh = 30;
vdisFilter(vdisSteerableDiff > vdisFilterThresh) = 1;

disp('Successfully compute v-disparity.');

%% Drivable Area Segmentation
% Hough Transform
[line, status] = HoughTransform(vdisFilter);
if(status == 0)
    disp('Hough transform failed.');
    return
end
point1 = line.point1;
point2 = line.point2;

% perform drivable area segmentation based on Hough Transform
drivableInitial = zeros(size(disparity));
drivableInitialThresh = 3;
for i = point1(2) : point2(2)
    d = (point2(1) - point1(1)) / (point2(2) - point1(2)) * i + (point1(1) * point2(2) - point2(1) * point1(2)) / (point2(2) - point1(2));
    for j = 1 : size(drivableInitial, 2)
        if(disparity(i, j) > d - drivableInitialThresh && disparity(i, j) < d + drivableInitialThresh)
            drivableInitial(i, j) = 1;
        end
    end
end
drivableFinal = medfilt2(drivableInitial, [5, 5]);

disp('Successfully perform drivable area segmentation.');

%% Depth Anomaly Map Generation
drivableBW = drivableFinal;     % used for boundary detection
drivableBW(1, :) = 0; drivableBW(end, :) = 0;
drivableBW(:, 1) = 0; drivableBW(:, end) = 0;
[B, L, N] = bwboundaries(~drivableBW);

% select the holes with a specific area range
depthAnom = zeros(size(drivableBW));
for i = 1 : N
    temp = zeros(size(drivableBW));
    boundary = B{i};
    for j = 1 : size(boundary, 1)
        temp(boundary(j, 1), boundary(j, 2)) = 1;
    end
    area = bwarea(temp);
    if area > 25 && area < 500
        for j = 1 : size(boundary, 1)
            depthAnom(boundary(j, 1), boundary(j, 2)) = 1;
        end
    end
end
depthAnom = imfill(depthAnom, 'holes');
drivablePlusDepthAnom = depthAnom | drivableFinal;

disp('Successfully generate the depth anomaly map.');
rgb=im2double(rgb);
%% RGB Anomaly Map Generation
lab = rgb2lab(rgb);
labFilter = gaussFilter(lab, 12);
rgbAnom = sum((labFilter - lab).^2, 3);
rgbAnom(drivablePlusDepthAnom == 0) = 0;
rgbAnom = mapminmax(rgbAnom, 0, 1);

disp('Successfully generate the RGB anomaly map.');

%% Road Anomaly Segmentation
anomaly = 0.5 * depthAnom + 0.5 * rgbAnom;
anomalyFinal = zeros(size(anomaly));
anomalyThresh = 0.5;
anomalyFinal(anomaly >= anomalyThresh) = 1;
anomalyFinal = medfilt2(anomalyFinal, [5, 5]);
disp('Successfully perform road anomaly segmentation.');

%% Save Generated Label and Visulization
label  = uint8(zeros(size(disparity)));
label(drivablePlusDepthAnom == 1) = 1;
label(anomalyFinal == 1) = 2;
vis = visualization(rgb, label);

mkdir(fullfile(ReadPath, 'output'));
imwrite(label, fullfile(ReadPath, 'output', [name(1:end-4), '_SSLG.png']));
imwrite(vis, fullfile(ReadPath, 'output', [name(1:end-4), '_SSLG_vis.png']));

disp('Successfully save the generated label.');
%% Displaying results 
figure,
subplot(121), imshow(vdis);title('Original V-Disparity Map')
subplot(122), imshow(vdisFilter);title('Filtered V-Disparity Map')
figure,
subplot(221),imshow(drivableFinal);title('Drivable Area')
subplot(222),imshow(rgbAnom);title('RGB Anomaly')
subplot(223), imshow(anomalyFinal);title('Final depth anomaly map')
subplot(224), imshow(vis);title('Self-supervised Label')
%%

[PSNR, MSE]=psnr_mse(I1,I)
[SSIM]=ssim_index(I(:,:,1),I1(:,:,1))