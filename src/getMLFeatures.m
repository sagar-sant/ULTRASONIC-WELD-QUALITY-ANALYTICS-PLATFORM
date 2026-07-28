%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : getMLFeatures.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Generates machine learning features for Intelligent Weld Learning Engine
% (IWLE) by executing the advanced weld analysis pipeline and returning
% the extracted feature vector used for supervised learning.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function mlFeatures = getMLFeatures( ...
    roiImage,...
    metadata)

%--------------------------------------------------------------
% Validate Metadata
%--------------------------------------------------------------

requiredFields = { ...
    'WeldTime', ...
    'Pressure', ...
    'Amplitude', ...
    'Material', ...
    'Thickness'};

for k = 1:length(requiredFields)

    if ~isfield(metadata, requiredFields{k})

        error('Missing metadata field: %s', requiredFields{k});

    end

end

%--------------------------------------------------------------
% Read Metadata
%--------------------------------------------------------------

weldTime  = metadata.WeldTime;
pressure  = metadata.Pressure;
amplitude = metadata.Amplitude;
material  = metadata.Material;
thickness = metadata.Thickness;

%--------------------------------------------------------------
% Run weld analysis
%--------------------------------------------------------------

results = ADVANCED_WELD_ANALYSIS1( ...
    roiImage,...
    weldTime,...
    pressure,...
    amplitude,...
    material,...
    thickness);

%--------------------------------------------------------------
% Return ML features
%--------------------------------------------------------------

mlFeatures = double(results.MLFeatures(:));

end