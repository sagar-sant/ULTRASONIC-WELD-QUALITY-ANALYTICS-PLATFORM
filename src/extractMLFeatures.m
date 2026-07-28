%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : extractMLFeatures.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Extracts the machine learning feature vector from the weld analysis
% results by combining defect characteristics, shape descriptors,
% texture features, quality metrics, and confidence information for
% Random Forest model training and prediction.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function featureVector = extractMLFeatures(results)

featureVector = [

%% ============================================================
% DEFECT FEATURES
%% ============================================================

results.crackCount

results.crackArea

results.areaRatio

results.maxLength

results.avgLength

results.crackDensity

%% ============================================================
% SHAPE FEATURES
%% ============================================================

results.shapeComplexity

results.severityIndex

%% ============================================================
% TEXTURE FEATURES
%% ============================================================

results.contrast

results.correlation

results.energy

results.homogeneity

results.entropy

%% ============================================================
% QUALITY FEATURES
%% ============================================================

results.qualityScore

results.confidence

];

featureVector = double(featureVector(:));

end