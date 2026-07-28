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