%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : detectWeldROI.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Automatically detects and localizes the weld Region of Interest (ROI)
% from ultrasonic weld images using image enhancement, gradient analysis,
% entropy analysis, candidate scoring, and automatic alignment to improve
% subsequent weld inspection accuracy.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% ============================================================
% AUTOMATIC WELD ROI DETECTION
%
% Version 2.0
% Professional Weld Localization
%% ============================================================

function [croppedImg,...
          bbox,...
          success,...
          confidence,...
          rotationAngle] = ...
          detectWeldROI(img)

%% ============================================================
% INITIALIZATION
%% ============================================================

success = false;

confidence = 0;

rotationAngle = 0;

bbox = [];

croppedImg = [];

%% ============================================================
% VALIDATE IMAGE
%% ============================================================

if isempty(img)

    return;

end

%% ============================================================
% CONVERT TO GRAYSCALE
%% ============================================================

if size(img,3)==3

    gray = rgb2gray(img);

else

    gray = img;

end

gray = im2double(gray);

%% ============================================================
% IMAGE ENHANCEMENT
%% ============================================================

gray = adapthisteq( ...
    gray,...
    'ClipLimit',0.02,...
    'NumTiles',[8 8]);

gray = imgaussfilt(gray,1.2);

%% ============================================================
% IMAGE QUALITY
%% ============================================================

quality = evaluateImageQuality(gray);

if quality.score < 0.35

    return;

end

%% ============================================================
% FEATURE MAPS
%% ============================================================

gradientMap = computeGradientMap(gray);

varianceMap = computeVarianceMap(gray);

entropyMap = computeEntropyMap(gray);

%% ============================================================
% ROI CANDIDATES
%% ============================================================

candidates = generateROICandidates( ...
                gradientMap,...
                varianceMap,...
                entropyMap);

if isempty(candidates)

    return;

end

%% ============================================================
% SCORE CANDIDATES
%% ============================================================

[bestBox,...
 bestScore] = ...
    selectBestROI( ...
    gray,...
    candidates);

bbox = bestBox;

%% ============================================================
% CONFIDENCE
%% ============================================================

confidence = max(0,min(bestScore,1));

%% ============================================================
% REFINE ROI
%% ============================================================

bbox = refineROI( ...
        bbox,...
        size(gray));

%% ============================================================
% CROP
%% ============================================================

expand = round(max(bbox(3:4)) * 0.25);

bbox(1) = max(1, bbox(1) - expand);
bbox(2) = max(1, bbox(2) - expand);

bbox(3) = min(size(img,2) - bbox(1) + 1, bbox(3) + 2*expand);
bbox(4) = min(size(img,1) - bbox(2) + 1, bbox(4) + 2*expand);

croppedImg = ...
    imcrop(img,bbox);

if isempty(croppedImg)

    return;

end

%% ============================================================
% AUTO ALIGNMENT
%% ============================================================

[croppedImg,...
 rotationAngle] = ...
    alignWeld(croppedImg);

%% ============================================================
% NORMALIZE SIZE
%% ============================================================

targetHeight = 700;

scale = ...
    targetHeight / ...
    size(croppedImg,1);

croppedImg = ...
    imresize( ...
    croppedImg,...
    scale,...
    'bicubic');

success = true;

end

%% ============================================================
% IMAGE QUALITY EVALUATION
%% ============================================================

function quality = evaluateImageQuality(gray)

quality = struct();

%% Sharpness

[Gmag,~] = imgradient(gray,'sobel');

sharpness = mean(Gmag(:));

%% Contrast

contrast = std2(gray);

%% Exposure

brightness = mean(gray(:));

exposure = ...
    1 - abs(brightness-0.5)/0.5;

%% Noise Estimate

noise = std2(gray-imgaussfilt(gray,2));

noiseScore = ...
    max(0,1-noise/0.10);

%% Overall Quality

quality.sharpness = sharpness;

quality.contrast = contrast;

quality.exposure = exposure;

quality.noise = noiseScore;

quality.score = ...
      0.35*mat2gray(sharpness) ...
    + 0.30*mat2gray(contrast) ...
    + 0.20*exposure ...
    + 0.15*noiseScore;

end

%% ============================================================
% GRADIENT MAP
%% ============================================================

function gradientMap = computeGradientMap(gray)

[Gx,Gy] = imgradientxy(gray,'sobel');

gradientMap = hypot(Gx,Gy);

gradientMap = mat2gray(gradientMap);

gradientMap = ...
    imgaussfilt(gradientMap,1);

end

%% ============================================================
% LOCAL VARIANCE MAP
%% ============================================================

function varianceMap = computeVarianceMap(gray)

kernel = true(21);

localMean = ...
    imfilter(gray,...
    kernel/sum(kernel(:)),...
    'replicate');

localSqMean = ...
    imfilter(gray.^2,...
    kernel/sum(kernel(:)),...
    'replicate');

varianceMap = ...
    localSqMean - localMean.^2;

varianceMap = ...
    mat2gray(varianceMap);

end

%% ============================================================
% ENTROPY MAP
%% ============================================================

function entropyMap = computeEntropyMap(gray)

entropyMap = entropyfilt( ...
    gray,...
    true(15));

entropyMap = ...
    mat2gray(entropyMap);

end

%% ============================================================
% GENERATE ROI CANDIDATES
%% ============================================================

function candidates = generateROICandidates( ...
    gradientMap,...
    varianceMap,...
    entropyMap)

combined = ...
      0.50*gradientMap ...
    + 0.30*varianceMap ...
    + 0.20*entropyMap;

combined = mat2gray(combined);

window = round(min(size(combined))/2);

step = max(round(window/6),10);

count = 0;

maxCandidates = ...
    ceil((size(combined,1)-window)/step) * ...
    ceil((size(combined,2)-window)/step);

candidates(maxCandidates) = struct( ...
    'BoundingBox',[],...
    'Score',0);

for y = 1:step:size(combined,1)-window

    for x = 1:step:size(combined,2)-window

        patch = ...
            combined( ...
            y:y+window-1,...
            x:x+window-1);

        meanEnergy = mean(patch(:));

        varianceEnergy = var(patch(:));

        score = ...
            0.70*meanEnergy + ...
            0.30*varianceEnergy;

        if score > 0.25

            count = count + 1;

            candidates(count).BoundingBox = ...
                [x y window window];

            candidates(count).Score = score;

        end

    end

end

if count == 0

    candidates = [];

else

    candidates = candidates(1:count);

end

end

%% ============================================================
% SELECT BEST ROI
%% ============================================================

function [bbox,...
          bestScore] = ...
          selectBestROI( ...
          gray,...
          candidates)

bestScore = -Inf;

bbox = [];

imageCenter = ...
[
size(gray,2)/2 ...
size(gray,1)/2
];

for k = 1:length(candidates)

    box = candidates(k).BoundingBox;

    x = box(1);

    y = box(2);

    w = box(3);

    h = box(4);

    patch = ...
        gray( ...
        y:y+h-1,...
        x:x+w-1);

    texture = std2(patch);

    entropyValue = entropy(patch);

    center = ...
    [
    x+w/2 ...
    y+h/2
    ];

    distance = norm( ...
        center-imageCenter);

    distanceScore = ...
        exp(-distance/250);

    finalScore = ...
          0.50*candidates(k).Score ...
         +0.25*texture ...
         +0.20*entropyValue ...
         +0.05*distanceScore;

    if finalScore >= bestScore

        bestScore = finalScore;

        bbox = box;

    end

end

bestScore = ...
    min(bestScore,1);

end

%% ============================================================
% REFINE ROI
%% ============================================================

function bbox = refineROI( ...
    bbox,...
    imageSize)

margin = round(max(bbox(3:4))*0.60);

bbox(1) = ...
    max(1,...
    floor(bbox(1)-margin));

bbox(2) = ...
    max(1,...
    floor(bbox(2)-margin));

bbox(3) = ...
    min( ...
    imageSize(2)-bbox(1),...
    ceil(bbox(3)+2*margin));

bbox(4) = ...
    min( ...
    imageSize(1)-bbox(2),...
    ceil(bbox(4)+2*margin));

end

%% ============================================================
% ALIGN WELD
%% ============================================================

function [aligned,...
          angle] = ...
          alignWeld(img)

if size(img,3)==3

    gray = rgb2gray(img);

else

    gray = img;

end

gray = im2double(gray);

edges = edge( ...
    gray,...
    'Canny');

[H,...
 T,...
 R] = ...
    hough(edges);

P = ...
    houghpeaks( ...
    H,...
    5);

lines = ...
    houghlines( ...
    edges,...
    T,...
    R,...
    P,...
    'FillGap',20,...
    'MinLength',40);

if isempty(lines)

    aligned = img;

    angle = 0;

    return;

end

angles = ...
    zeros(length(lines),1);

for k = 1:length(lines)

    angles(k) = ...
        lines(k).theta;

end

angle = median(angles);

aligned = ...
    imrotate( ...
    img,...
    -angle,...
    'bicubic',...
    'crop');

end