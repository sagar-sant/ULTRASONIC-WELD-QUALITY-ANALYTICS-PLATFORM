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