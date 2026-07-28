function results = ADVANCED_WELD_ANALYSIS1( ...
    inputImage,...
    weldTime,...
    pressure,...
    amplitude,...
    material,...
    thickness)

%% ============================================================
% MATERIAL IMAGE PARAMETERS
%% ============================================================

params = getImageProcessingParameters( ...
    material,...
    thickness);
 
%% ============================================================
% ADVANCED_WELD_ANALYSIS1
%
% Professional Ultrasonic Weld Inspection Engine
%
% PART 1
% - Input Validation
% - Image Preprocessing
% - CLAHE Enhancement
% - Noise Reduction
% - Multi-Directional Black-Hat Enhancement
% - Adaptive Thresholding
% - Morphological Cleanup
%
% Part 2:
% - Crack Feature Extraction
% - GLCM Analysis
% - Quality Scoring
%
% Part 3:
% - Heatmaps
% - Overlays
% - Root Cause Analysis
% ============================================================

%% ============================================================
% INITIALIZE RESULTS
%% ============================================================
   
results = struct();

results.weldTime = weldTime;
results.pressure = pressure;
results.amplitude = amplitude;

%% ============================================================
% INPUT VALIDATION
%% ============================================================

if isempty(inputImage)

    error('Input image is empty.');

end

if ~ismatrix(inputImage) && size(inputImage,3) ~= 3

    error('Unsupported image format.');

end

%% ============================================================
% STORE ORIGINAL IMAGE
%% ============================================================

results.originalImage = inputImage;

%% ============================================================
% CONVERT TO GRAYSCALE
%% ============================================================

if size(inputImage,3) == 3

    grayImage = rgb2gray(inputImage);

else

    grayImage = inputImage;

end

grayImage = im2uint8(grayImage);

%% ============================================================
% METAL SPECIMEN DETECTION
%% ============================================================

% Convert original image to HSV
hsvImg = rgb2hsv(inputImage);

% H = hsvImg(:,:,1);
S = hsvImg(:,:,2);
V = hsvImg(:,:,3);

% Metal is generally low saturation
metalMask = S < 0.35;

% Remove very dark pixels (black padding)
metalMask = metalMask & (V > 0.15);

% Fill holes
metalMask = imfill(metalMask,'holes');

% Remove tiny objects
metalMask = bwareaopen(metalMask,500);

% Keep largest connected component
metalMask = bwareafilt(metalMask,1);

results.metalMask = metalMask;

%% ============================================================
% REMOVE BLACK ROTATION BORDERS
%% ============================================================

% Create a mask of valid image pixels (exclude black padding)
validMask = grayImage > 10;

% Fill small gaps
validMask = imfill(validMask, 'holes');

% Keep only the largest connected region
validMask = bwareafilt(validMask, 1);

% Apply the mask
grayImage(~validMask) = 255;

results.validMask = validMask;

results.grayImage = grayImage;

%% ============================================================
% WELD TEXTURE MAP
%% ============================================================

textureMap = stdfilt(grayImage, true(5));

textureMap = mat2gray(textureMap);

results.textureMap = textureMap;

%% ============================================================
% AUTOMATIC WELD ROI
%% ============================================================

[croppedROI,...
 roiBox,...
 success,...
 roiConfidence,...
 rotationAngle] = detectWeldROI(inputImage);

results.roiSuccess = success;
results.roiConfidence = roiConfidence;
results.rotationAngle = rotationAngle;

if success

    weldMask = false(size(grayImage));

    x = round(roiBox(1));
    y = round(roiBox(2));
    w = round(roiBox(3));
    h = round(roiBox(4));

    x = max(1,x);
    y = max(1,y);

    x2 = min(size(grayImage,2),x+w-1);
    y2 = min(size(grayImage,1),y+h-1);

    weldMask(y:y2,x:x2) = true;

else

    warning('ROI detection failed.');

    weldMask = false(size(grayImage));

    % use the image centre as fallback
    cx = round(size(grayImage,2)/2);
    cy = round(size(grayImage,1)/2);

    w = round(size(grayImage,2)*0.30);
    h = round(size(grayImage,1)*0.30);

    weldMask(cy-h/2:cy+h/2,...
             cx-w/2:cx+w/2) = true;

end

results.weldMask = weldMask;
results.croppedROI = croppedROI;

%% ============================================================
% STEP 1
% CONTRAST ENHANCEMENT (CLAHE)
%% ============================================================

enhancedImage = adapthisteq( ...
    grayImage,...
    'ClipLimit',params.claheClipLimit,...
    'NumTiles',[8 8]);

%% ============================================================
% STEP 2
% MEDIAN FILTER DENOISING
%% ============================================================

enhancedImage = medfilt2( ...
    enhancedImage,...
    [3 3]);

%% ============================================================
% STEP 3
% GAUSSIAN SMOOTHING
%% ============================================================

enhancedImage = imgaussfilt( ...
    enhancedImage,...
    params.gaussianSigma);

results.enhancedImage = enhancedImage;

%% ============================================================
% STEP 4
% MULTI-DIRECTION BLACK-HAT CRACK ENHANCEMENT
%% ============================================================

seLength = params.blackHatLength;

bh0 = imbothat( ...
    enhancedImage,...
    strel('line',seLength,0));

bh45 = imbothat( ...
    enhancedImage,...
    strel('line',seLength,45));

bh90 = imbothat( ...
    enhancedImage,...
    strel('line',seLength,90));

bh135 = imbothat( ...
    enhancedImage,...
    strel('line',seLength,135));

blackhatImage = max( ...
    cat(3,...
    bh0,...
    bh45,...
    bh90,...
    bh135),...
    [],3);

results.blackhatImage = blackhatImage;

%% ============================================================
% STEP 5
% NORMALIZE BLACK-HAT RESPONSE
%% ============================================================

blackhatImage = mat2gray(blackhatImage);

% Restrict crack response to weld region
blackhatImage(~weldMask) = 0;

%% ============================================================
% STEP 6
% ADAPTIVE THRESHOLD
%% ============================================================

thresholdLevel = graythresh(blackhatImage);

thresholdLevel = thresholdLevel * 1.40;

binaryMap = imbinarize(blackhatImage,thresholdLevel);

binaryMap = binaryMap & weldMask;

results.thresholdLevel = thresholdLevel;

%% ============================================================
% STEP 7
% REMOVE SMALL NOISE OBJECTS
%% ============================================================

binaryMap = bwareaopen( ...
    binaryMap,...
    round(params.minCrackArea/3));

binaryMap = binaryMap & results.weldMask;

binaryMap = imclearborder(binaryMap);

binaryMap = bwareaopen(binaryMap,60);

%% ============================================================
% STEP 8
% MORPHOLOGICAL CLEANUP
%% ============================================================

closeLen = max(3,params.closeRadius*2);

binaryMap = imopen(binaryMap, strel('disk',2));

binaryMap = imclose(binaryMap, strel('line',closeLen,0));

binaryMap = imclose(binaryMap, strel('line',closeLen,90));

binaryMap = imfill(binaryMap,'holes');

binaryMap = binaryMap & weldMask;

%% ============================================================
% STEP 10
% FINAL CLEANUP
%% ============================================================

binaryMap = bwareaopen( ...
    binaryMap,...
    round(params.minCrackArea/2));

results.binaryMap = binaryMap;

%% ============================================================
% STEP 10A
% FRACTURE DETECTION
%% ============================================================

% Detect large dark separations in the weld

localROI = mat2gray(blackhatImage);

localROI(~weldMask) = 0;

level = graythresh(localROI);

fractureMask = imbinarize(localROI, level * 1.8);

% Only analyse inside weld ROI
fractureMask = fractureMask & weldMask;

% Ignore a border around the weld ROI to avoid shadows
border = imerode(weldMask, strel('disk',18));

fractureMask = fractureMask & border;

% Remove tiny objects
fractureMask = bwareaopen(fractureMask,900);

% Close gaps
fractureMask = imclose(fractureMask,strel('disk',4));

% Fill holes
fractureMask = imfill(fractureMask,'holes');
fractureMask = bwareafilt(fractureMask,[900 inf]);

fractureStats = regionprops( ...
    fractureMask,...
    'Area',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'BoundingBox',...
    'Perimeter',...
    'Eccentricity',...
    'Solidity',...
    'Extent',...
    'ConvexArea');

fractureDetected = false;

largestFractureArea = 0;
largestFractureLength = 0;
fractureCount = 0;

validatedFractureMask = false(size(fractureMask));

CCfracture = bwconncomp(fractureMask);

[h, w] = size(fractureMask);

for k = 1:length(fractureStats)

    area = fractureStats(k).Area;

    majorLength = fractureStats(k).MajorAxisLength;

    minorLength = fractureStats(k).MinorAxisLength;

    ecc = fractureStats(k).Eccentricity;

    solidity = fractureStats(k).Solidity;

    extent = fractureStats(k).Extent;

    convexArea = fractureStats(k).ConvexArea;

    convexDeficiency = convexArea - area;

    bbox = fractureStats(k).BoundingBox;

    x = bbox(1);
    y = bbox(2);
    bw = bbox(3);
    bh = bbox(4);

    % Reject anything touching the ROI border
    margin = 10;

    if x <= margin || ...
       y <= margin || ...
        (x + bw) >= (w - margin) || ...
        (y + bh) >= (h - margin)

            continue;

    end

    bboxArea = bbox(3)*bbox(4);

    fillRatio = area/max(bboxArea,1);

    perimeter = fractureStats(k).Perimeter;

    circularity = 4*pi*area/(perimeter^2+eps);

    aspectRatio = majorLength / max(minorLength,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reject weld nugget / compact blobs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if solidity > 0.93 && ...
       fillRatio > 0.82 && ...
       circularity > 0.55

       continue;

    end

    isFracture = false;

    %==========================================================
    % MODEL 1
    % Long thin fracture
    %==========================================================

    if area > 900 && ...
       majorLength > 150 && ...
       aspectRatio > 8 && ...
       ecc > 0.95 && ...
       solidity < 0.95

        isFracture = true;

    end

    %==========================================================
    % MODEL 2
    % Wide jagged fracture
    %==========================================================

    if area > 700 && ...
       majorLength > 80 && ...
       solidity < 0.80 && ...
       convexDeficiency > 150

        isFracture = true;

    end

    %==========================================================
    % MODEL 3
    % Broken nugget
    %==========================================================

    %if area > 1200 && ...
     %  extent < 0.65 && ...
      % solidity < 0.90

       % isFracture = true;

   % end

    %==========================================================
    % MODEL 4
    % Massive material separation
    %==========================================================

    if area > 2200 && ...
       majorLength > 120 && ...
       solidity < 0.85 && ...
       extent < 0.75 && ...
       circularity < 0.45

        isFracture = true;

    end

    %==========================================================
    % VALID FRACTURE
    %==========================================================

    if isFracture

        validatedFractureMask(CCfracture.PixelIdxList{k}) = true;

        fractureCount = fractureCount + 1;

        fractureDetected = true;

        if area > largestFractureArea

            largestFractureArea = area;

            largestFractureLength = majorLength;

        end

    end

end

results.fractureMask = validatedFractureMask;
results.fractureDetected  = fractureDetected;
results.fractureArea      = largestFractureArea;
results.fractureLength    = largestFractureLength;
results.fractureCount     = fractureCount;

%% ============================================================
% CONNECTED COMPONENT ANALYSIS
%% ============================================================

CC = bwconncomp(binaryMap);

results.connectedComponents = CC;

%% ============================================================
% STEP 11
% REGION PROPERTIES
%% ============================================================

regionStats = regionprops( ...
    CC,...
    blackhatImage,...
    'Area',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'Eccentricity',...
    'Solidity',...
    'Extent',...
    'MeanIntensity',...
    'PixelIdxList');

%% ============================================================
% STORE ALL CANDIDATE REGIONS
%% ============================================================

results.regionStats = regionStats;

%% ============================================================
% STEP 12
% ASPECT-RATIO FILTERING
%
% Keeps long crack-like structures.
%% ============================================================

validMask = false(size(binaryMap));

for k = 1:length(regionStats)

    area  = regionStats(k).Area;
    major = regionStats(k).MajorAxisLength;
    minor = regionStats(k).MinorAxisLength;

% Reject short, wide features that are more likely
% to be surface scratches than true weld cracks.
    estimatedWidth = minor;

    if estimatedWidth > 6 && major < 40
        continue;
    end

    aspectRatio = major / max(minor,1);

    ecc      = regionStats(k).Eccentricity;
    solidity = regionStats(k).Solidity;
    extent   = regionStats(k).Extent;

    meanIntensity = regionStats(k).MeanIntensity;

    if area < params.minCrackArea
        continue;
    end

    if area > params.maxCrackArea
        continue;
    end

    % More relaxed minimum length
    if major < 20
        continue;
    end

    if major > params.maxCrackLength
        continue;
    end

    % More relaxed aspect ratio
    if aspectRatio < 3
        continue;
    end

    % More relaxed eccentricity
    if ecc < 0.80
        continue;
    end

    % More relaxed solidity
    if solidity < 0.40
        continue;
    end

    % More relaxed extent
    if extent < 0.25
        continue;
    end

    if meanIntensity < 0.40
    continue;
    end

    validMask(CC.PixelIdxList{k}) = true;

end

%% ============================================================
% BUILD FINAL CRACK MAP
%% ============================================================

crackMap = validMask;

crackMap = bwareaopen(crackMap,20);

crackMap = bwskel(crackMap);

crackMap = bwmorph(crackMap,'spur',5);

se = strel('disk',1);

crackMap = imclose(crackMap,se);

results.crackMap = crackMap;

%% ============================================================
% STEP 13
% FINAL CRACK COMPONENTS
%% ============================================================

CC = bwconncomp(crackMap);

crackStats = regionprops( ...
    CC,...
    'Area',...
    'BoundingBox',...
    'MajorAxisLength',...
    'MinorAxisLength',...
    'Perimeter',...
    'Eccentricity',...
    'Orientation');

minArea   = max(20, round(params.minCrackArea/2));
minEcc    = 0.90;
minLength = 20;

validIdx = false(length(crackStats),1);

for k = 1:length(crackStats)

    area = crackStats(k).Area;

    ecc = crackStats(k).Eccentricity;

    majorLen = crackStats(k).MajorAxisLength;
    
    if area < minArea
        continue;
    end

    if ecc < minEcc
        continue;
    end

    if majorLen < minLength
        continue;
    end

    if majorLen > params.maxCrackLength
        continue;
    end

    validIdx(k) = true;

 end

crackStats = crackStats(validIdx);

results.crackStats = crackStats;
%% ============================================================
% STEP 14
% CRACK COUNT
%% ============================================================

validAreas = [crackStats.Area];

crackCount = sum( ...
    validAreas > params.minCrackArea);

results.crackCount = crackCount;

%% ============================================================
% STEP 15
% TOTAL CRACK AREA
%% ============================================================

if isempty(crackStats)

    crackArea = 0;

else

    crackArea = sum([crackStats.Area]);

end

results.crackArea = crackArea;

%% ============================================================
% STEP 16
% AREA RATIO
%% ============================================================

imageArea = numel(crackMap);

areaRatio = crackArea / max(imageArea,1);

results.areaRatio = areaRatio;

%% ============================================================
% STEP 17
% MAXIMUM CRACK LENGTH
%% ============================================================

if crackCount == 0

    maxLength = 0;

elseif isempty(crackStats)

    maxLength = 0;

else

    maxLength = max([crackStats.MajorAxisLength]);

end

results.maxLength = maxLength;

%% ============================================================
% STEP 18
% AVERAGE CRACK LENGTH
%% ============================================================

if crackCount == 0

    avgLength = 0;

elseif isempty(crackStats)

    avgLength = 0;

else

    avgLength = mean([crackStats.MajorAxisLength]);

end

results.avgLength = avgLength;

%% ============================================================
% STEP 19
% CRACK DENSITY
%% ============================================================

crackDensity = crackCount / ...
    max(imageArea,1);

results.crackDensity = crackDensity;

%% ============================================================
% STEP 20
% SHAPE COMPLEXITY
%% ============================================================

complexityValues = zeros(1,length(crackStats));

for k = 1:length(crackStats)

    perimeter = crackStats(k).Perimeter;

    area = crackStats(k).Area;

    complexity = ...
        (perimeter^2) / ...
        max(4*pi*area,1);

    complexity = min(complexity,50);

    complexityValues(k) = complexity;

end

if isempty(complexityValues)

    shapeComplexity = 0;

else

    shapeComplexity = ...
        mean(complexityValues);

end

results.shapeComplexity = shapeComplexity;

%% ============================================================
% STEP 21
% TEXTURE FEATURES (GLCM)
%% ============================================================

roiImage = enhancedImage;
roiImage(~weldMask) = 0;

glcm = graycomatrix( ...
    roiImage,...
    'Offset',[0 1]);

textureStats = graycoprops( ...
    glcm,...
    {'Contrast',...
     'Correlation',...
     'Energy',...
     'Homogeneity'});

results.contrast = ...
    textureStats.Contrast;

results.correlation = ...
    textureStats.Correlation;

results.energy = ...
    textureStats.Energy;

results.homogeneity = ...
    textureStats.Homogeneity;

%% ============================================================
% STEP 22
% IMAGE ENTROPY
%% ============================================================

results.entropy = entropy(roiImage);

%% ============================================================
% STEP 23
% NORMALIZED QUALITY METRICS
%% ============================================================

normDensity = min( ...
    crackDensity * 25,...
    1);

normArea = min( ...
    areaRatio * 150,...
    1);

normLength = min( ...
    maxLength / 150,...
    1);

normComplexity = min( ...
    shapeComplexity / 20,...
    1);

normTexture = min( ...
    results.contrast / 200,...
    1);

%% ============================================================
% STEP 24
% QUALITY SCORE MODEL
%% ============================================================

penalty = ...
    params.weightDensity    * normDensity + ...
    params.weightArea       * normArea + ...
    params.weightLength     * normLength + ...
    params.weightComplexity * normComplexity + ...
    params.weightTexture    * normTexture;

qualityScore = ...
    max(0,...
    min(100,...
    100 - penalty));

results.qualityScore = ...
    qualityScore;

%% ============================================================
% STEP 25
% CONFIDENCE SCORE
%% ============================================================

confidence = ...
    0.45 + ...
    0.20*results.energy + ...
    0.15*results.homogeneity + ...
    0.10*(1-min(normDensity,1)) + ...
    0.10*roiConfidence;
confidence = ...
    min(max(confidence,0),1);

results.confidence = confidence;

%% ============================================================
% STEP 26
% SEVERITY LEVEL
%% ============================================================

severityIndex = ...
    crackCount*2 + ...
    areaRatio*100 + ...
    maxLength/50;

if severityIndex < params.lowSeverity

    severity = 'LOW';

elseif severityIndex < params.mediumSeverity

    severity = 'MODERATE';

elseif severityIndex < params.highSeverity

    severity = 'HIGH';

else

    severity = 'SEVERE';

end

results.severity = severity;
results.severityIndex = severityIndex;

%% ------------------------------------------------------------
% FRACTURE OVERRIDE
%% ------------------------------------------------------------

if results.fractureDetected

    results.severity = 'SEVERE';

    results.severityIndex = ...
        results.severityIndex + 100;

end

%% ============================================================
% INSPECTION GRADE
%% ============================================================

inspectionScore = 100;

inspectionScore = inspectionScore ...
    - crackCount*6 ...
    - areaRatio*8000 ...
    - maxLength*0.15 ...
    - shapeComplexity*0.4;

inspectionScore = max(0,min(100,inspectionScore));

results.inspectionScore = inspectionScore;

%% ============================================================
% Step 27 RULE-BASED INSPECTION ENGINE
%% ============================================================

% Perfect weld
if crackCount == 0 && ...
   areaRatio < 0.0007 && ...
   maxLength < 30 && ...
   qualityScore >= 85 && ...
   confidence >= 0.75

    status = "GOOD";

% Critical defects override everything
elseif maxLength > params.criticalCrackLength || ...
       areaRatio > params.criticalAreaRatio || ...
       crackCount > params.criticalCrackCount

    status = "DEFECTIVE";

% Minor defects are acceptable
elseif any(strcmpi(severity, {'LOW','MODERATE'})) && ...
       qualityScore >= 70

    status = "ACCEPTABLE";

% Everything else is defective
else

    status = "DEFECTIVE";

end

%% ------------------------------------------------------------
% FRACTURE OVERRIDE
%% ------------------------------------------------------------

if results.fractureDetected

    status = "DEFECTIVE";

    results.qualityScore = min(results.qualityScore,30);

end

results.status = status;

%% ============================================================
% Step 28 DEFECT DESCRIPTION
%% ============================================================

if results.fractureDetected

    defectType = "MAJOR WELD FRACTURE";

elseif crackCount == 0

    defectType = "NO DEFECT";

elseif crackCount <= 2

    defectType = "MINOR SURFACE CRACK";

elseif crackDensity < 2e-5

    defectType = "NON-EXTRUSION CRACK";

else

    defectType = "MATERIAL EXTRUSION CRACK";

end

results.defectType = defectType;

%% ============================================================
% STEP 29
% BOUNDING BOX EXTRACTION
%% ============================================================

results.boundingBoxes = [];

if ~isempty(crackStats)

    minArea = params.minCrackArea;

    validIdx = [crackStats.Area] >= minArea;

if any(validIdx)

    bboxArray = reshape( ...
        [crackStats(validIdx).BoundingBox], ...
        4,[])';

    results.boundingBoxes = bboxArray;

else

    results.boundingBoxes = [];

end
end

%% ============================================================
% STEP 30
% CRACK STATISTICS SUMMARY
%% ============================================================

if isempty(crackStats)

    results.avgArea = 0;
    results.maxArea = 0;

else

    areas = [crackStats.Area];

    results.avgArea = mean(areas);
    results.maxArea = max(areas);

end

%% ============================================================
% STEP 31
% REGION METRICS
%% ============================================================

results.regionCount = crackCount;

if isempty(crackStats)

    results.avgEccentricity = 0;

else

    results.avgEccentricity = ...
        mean([crackStats.Eccentricity]);

end

%% ============================================================
% STEP 32
% ANALYSIS SUMMARY
%% ============================================================

results.analysisCompleted = true;

results.analysisVersion = ...
    'ADVANCED_WELD_ANALYSIS_V3';

results.timestamp = datetime('now');

%% ============================================================
% STEP 33
% HEATMAP GENERATION
%% ============================================================

heatmapImage = createHeatmapOverlay(...
    results.originalImage,...
    blackhatImage);

results.heatmapImage = heatmapImage;

%% ============================================================
% STEP 34
% CRACK OVERLAY IMAGE
%% ============================================================

combinedMap = crackMap | results.fractureMask;

overlayImage = createOverlayImage( ...
    results.originalImage,...
    combinedMap);

results.overlayImage = overlayImage;

%% ============================================================
% STEP 35
% BOUNDING BOX VISUALIZATION
%% ============================================================

bboxImage = createBoundingBoxImage(...
    results.originalImage,...
    crackStats,...
    params);

results.boundingBoxImage = bboxImage;

%% ============================================================
% STEP 36
% ROOT CAUSE ANALYSIS
%% ============================================================

rootCauses = {};

tol = params.parameterTolerance;

[optTime,...
 optPressure,...
 optAmplitude,...
 ~] = ...
    getRecommendedParameters( ...
    material,...
    thickness);

if crackCount == 0

    rootCauses{end+1} = ...
        'No significant weld defects detected';

else

    %% --------------------------------------------------------
    % PRESSURE
    %% --------------------------------------------------------

    if pressure < (1-tol) * optPressure

        rootCauses{end+1} = ...
            'Insufficient weld pressure';

    elseif pressure > (1+tol) * optPressure

        rootCauses{end+1} = ...
            'Excessive weld pressure';

    end

    %% --------------------------------------------------------
    % WELD TIME
    %% --------------------------------------------------------

    if weldTime < (1-tol) * optTime

        rootCauses{end+1} = ...
            'Weld time too short';

    elseif weldTime > (1+tol) * optTime

        rootCauses{end+1} = ...
            'Excessive weld time';

    end

    %% --------------------------------------------------------
    % AMPLITUDE
    %% --------------------------------------------------------

    if amplitude < (1-tol) * optAmplitude

        rootCauses{end+1} = ...
            'Insufficient vibration amplitude';

    elseif amplitude > (1+tol) * optAmplitude

        rootCauses{end+1} = ...
            'Excessive vibration amplitude';

    end

    %% --------------------------------------------------------
    % CRACK AREA
    %% --------------------------------------------------------

    if areaRatio > params.minorAreaRatio

        rootCauses{end+1} = ...
            'Large crack area detected';

    end

    %% --------------------------------------------------------
    % CRACK DENSITY
    %% --------------------------------------------------------

    if crackDensity > params.maxCrackDensity

        rootCauses{end+1} = ...
            'High crack density observed';

    end

    %% --------------------------------------------------------
    % DEFAULT
    %% --------------------------------------------------------

    if isempty(rootCauses)

        rootCauses{end+1} = ...
            'Possible tooling, alignment or material issue';

    end

end

results.rootCauses = rootCauses;

%% ============================================================
% STEP 37
% RECOMMENDED ACTIONS
%% ============================================================

recommendations = {};

recommendations{end+1} = ...
    sprintf('Quality Score : %.1f /100',qualityScore);

recommendations{end+1} = ...
    ['Inspection Result : ' char(status)];

recommendations{end+1} = '';

switch upper(string(status))

    %% ============================================================
    % GOOD WELD
    %% ============================================================

    case "GOOD"

        recommendations{end+1} = ...
            'Continue production';

        recommendations{end+1} = ...
            'Process parameters are within acceptable limits';

        recommendations{end+1} = ...
            'No corrective action required';

    %% ============================================================
    % ACCEPTABLE WELD
    %% ============================================================

    case "ACCEPTABLE"

        recommendations{end+1} = ...
            'Continue production with monitoring';

        recommendations{end+1} = ...
            'Inspect weld consistency periodically';

        recommendations{end+1} = ...
            'Review process parameters if quality trends downward';

    %% ============================================================
    % DEFECTIVE WELD
    %% ============================================================

    case "DEFECTIVE"

        recommendations{end+1} = ...
            'Stop production for inspection';

        recommendations{end+1} = ...
            'Adjust welding process parameters';

        recommendations{end+1} = ...
            'Inspect tooling and sonotrode condition';

        recommendations{end+1} = ...
            'Review weld settings and material alignment';

        recommendations{end+1} = ...
            'Perform detailed inspection before resuming production';

end

results.recommendations = recommendations;

%% ============================================================
% STEP 38
% FINAL VALIDATION
%% ============================================================

requiredFields = {

    'originalImage'
    'enhancedImage'
    'crackMap'
    'overlayImage'
    'qualityScore'
    'confidence'
    'crackCount'
    'severity'
    'status'
    };

for k = 1:length(requiredFields)

    if ~isfield(results,requiredFields{k})

        error( ...
            ['Missing result field: ',...
            requiredFields{k}]);

    end

end

%% ============================================================
% STEP 39
% MACHINE LEARNING FEATURE VECTOR
%% ============================================================

results.MLFeatures = extractMLFeatures(results);

results.Label = status;

results.RuleBasedPrediction = status;

results.featureDimension = length(results.MLFeatures);

%% ============================================================
% ANALYSIS COMPLETE
%% ============================================================

results.analysisCompleted = true;

end

%% ============================================================
% HELPER FUNCTIONS
%% ============================================================

function overlayImage = createOverlayImage(img,crackMap)

    if size(img,3) == 1

        img = repmat(img,[1 1 3]);

    end

    overlayImage = labeloverlay( ...
        img,...
        crackMap,...
        'Transparency',0.35);

end

%% ============================================================

function heatmapImage = createHeatmapOverlay(img,blackhatImage)

if size(img,3)==1

    rgb = repmat(img,[1 1 3]);

else

    rgb = img;

end

rgb = im2double(rgb);

heat = imgaussfilt(blackhatImage,4);

heat = mat2gray(heat);

heatRGB = ind2rgb( ...
    gray2ind(heat,256),...
    jet(256));

alphaMask = 0.45;

heatmapImage = ...
    rgb*(1-alphaMask) + ...
    heatRGB*alphaMask;

end

%% ============================================================
% BOUNDING BOX IMAGE
%% ============================================================

function bboxImage = createBoundingBoxImage( ...
    img,...
    crackStats,...
    params)

if size(img,3)==1

    rgb = repmat(img,[1 1 3]);

else

    rgb = img;

end

bboxImage = im2uint8(rgb);

if isempty(crackStats)
    return;
end

minArea = max(10, round(params.minCrackArea/4));

validIdx = [crackStats.Area] >= minArea;

if ~any(validIdx)
    return;
end

boxes = reshape( ...
    [crackStats(validIdx).BoundingBox],...
    4,[])';

try

    bboxImage = insertShape( ...
        bboxImage,...
        'Rectangle',...
        boxes,...
        'Color','green',...
        'LineWidth',3);

catch

end

end