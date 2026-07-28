%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : getImageProcessingParameters.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Returns optimized image processing parameters based on weld material
% type and specimen thickness. These parameters control preprocessing,
% crack detection, morphological operations, and quality assessment
% throughout the inspection pipeline.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ============================================================
% MATERIAL IMAGE PROCESSING PARAMETERS
% Adaptive image processing profile
%% ============================================================

function params = getImageProcessingParameters( ...
    material,...
    thickness)

switch material

%% ============================================================
% COPPER
%% ============================================================

case 'Copper'

    if thickness <= 0.2

        params.gaussianSigma       = 0.8;
        params.claheClipLimit      = 0.015;
        params.adaptiveSensitivity = 0.42;
        params.minCrackArea        = 40;
        params.maxCrackArea        = 1200;
        params.minCrackLength      = 15;
        params.maxCrackLength      = 180;
        params.minAspectRatio      = 6;
        params.minEccentricity     = 0.88;
        params.closeRadius         = 1;
        params.blackHatLength      = 9;

    elseif thickness <= 0.5

        params.gaussianSigma       = 1.2;
        params.claheClipLimit      = 0.020;
        params.adaptiveSensitivity = 0.45;
        params.minCrackArea        = 80;
        params.maxCrackArea        = 1800;
        params.minCrackLength      = 20;
        params.maxCrackLength      = 220;
        params.minAspectRatio      = 7;
        params.minEccentricity     = 0.90;
        params.closeRadius         = 2;
        params.blackHatLength      = 15;

    elseif thickness <= 1.0

        params.gaussianSigma       = 1.5;
        params.claheClipLimit      = 0.025;
        params.adaptiveSensitivity = 0.48;
        params.minCrackArea        = 120;
        params.maxCrackArea        = 2200;
        params.minCrackLength      = 25;
        params.maxCrackLength      = 260;
        params.minAspectRatio      = 8;
        params.minEccentricity     = 0.92;
        params.closeRadius         = 3;
        params.blackHatLength      = 21;

    else

        params.gaussianSigma       = 1.8;
        params.claheClipLimit      = 0.030;
        params.adaptiveSensitivity = 0.50;
        params.minCrackArea        = 180;
        params.maxCrackArea        = 3000;
        params.minCrackLength      = 35;
        params.maxCrackLength      = 320;
        params.minAspectRatio      = 8;
        params.minEccentricity     = 0.94;
        params.closeRadius         = 3;
        params.blackHatLength      = 27;

    end

%% ============================================================
% ALUMINUM
%% ============================================================

case 'Aluminum'

    if thickness <= 0.2

        params.gaussianSigma       = 0.7;
        params.claheClipLimit      = 0.012;
        params.adaptiveSensitivity = 0.40;
        params.minCrackArea        = 35;
        params.maxCrackArea        = 1000;
        params.minCrackLength      = 12;
        params.maxCrackLength      = 160;
        params.minAspectRatio      = 6;
        params.minEccentricity     = 0.85;
        params.closeRadius         = 1;
        params.blackHatLength      = 9;

    elseif thickness <= 0.5

        params.gaussianSigma       = 1.0;
        params.claheClipLimit      = 0.015;
        params.adaptiveSensitivity = 0.45;
        params.minCrackArea        = 60;
        params.maxCrackArea        = 1600;
        params.minCrackLength      = 18;
        params.maxCrackLength      = 220;
        params.minAspectRatio      = 7;
        params.minEccentricity     = 0.88;
        params.closeRadius         = 2;
        params.blackHatLength      = 15;

    elseif thickness <= 1.0

        params.gaussianSigma       = 1.3;
        params.claheClipLimit      = 0.020;
        params.adaptiveSensitivity = 0.48;
        params.minCrackArea        = 100;
        params.maxCrackArea        = 2200;
        params.minCrackLength      = 22;
        params.maxCrackLength      = 260;
        params.minAspectRatio      = 8;
        params.minEccentricity     = 0.90;
        params.closeRadius         = 2;
        params.blackHatLength      = 21;

    else

        params.gaussianSigma       = 1.5;
        params.claheClipLimit      = 0.025;
        params.adaptiveSensitivity = 0.50;
        params.minCrackArea        = 150;
        params.maxCrackArea        = 2800;
        params.minCrackLength      = 30;
        params.maxCrackLength      = 320;
        params.minAspectRatio      = 8;
        params.minEccentricity     = 0.92;
        params.closeRadius         = 3;
        params.blackHatLength      = 27;

    end

%% ============================================================
% BRASS
%% ============================================================

case 'Brass'

    params.gaussianSigma       = 1.3;
    params.claheClipLimit      = 0.020;
    params.adaptiveSensitivity = 0.48;
    params.minCrackArea        = 80;
    params.maxCrackArea        = 2200;
    params.minCrackLength      = 20;
    params.maxCrackLength      = 250;
    params.minAspectRatio      = 8;
    params.minEccentricity     = 0.90;
    params.closeRadius         = 2;
    params.blackHatLength      = 15;

%% ============================================================
% STEEL
%% ============================================================

case 'Steel'

    params.gaussianSigma       = 1.8;
    params.claheClipLimit      = 0.030;
    params.adaptiveSensitivity = 0.55;
    params.minCrackArea        = 120;
    params.maxCrackArea        = 3000;
    params.minCrackLength      = 25;
    params.maxCrackLength      = 300;
    params.minAspectRatio      = 8;
    params.minEccentricity     = 0.92;
    params.closeRadius         = 3;
    params.blackHatLength      = 21;

%% ============================================================
% TITANIUM
%% ============================================================

case 'Titanium'

    params.gaussianSigma       = 1.5;
    params.claheClipLimit      = 0.025;
    params.adaptiveSensitivity = 0.52;
    params.minCrackArea        = 100;
    params.maxCrackArea        = 2600;
    params.minCrackLength      = 20;
    params.maxCrackLength      = 280;
    params.minAspectRatio      = 8;
    params.minEccentricity     = 0.90;
    params.closeRadius         = 3;
    params.blackHatLength      = 21;

%% ============================================================
% NICKEL
%% ============================================================

case 'Nickel'

    params.gaussianSigma       = 1.5;
    params.claheClipLimit      = 0.025;
    params.adaptiveSensitivity = 0.50;
    params.minCrackArea        = 90;
    params.maxCrackArea        = 2400;
    params.minCrackLength      = 20;
    params.maxCrackLength      = 260;
    params.minAspectRatio      = 8;
    params.minEccentricity     = 0.90;
    params.closeRadius         = 2;
    params.blackHatLength      = 21;

%% ============================================================
% ABS PLASTIC
%% ============================================================

case 'ABS Plastic'

    params.gaussianSigma       = 0.8;
    params.claheClipLimit      = 0.010;
    params.adaptiveSensitivity = 0.42;
    params.minCrackArea        = 40;
    params.maxCrackArea        = 1000;
    params.minCrackLength      = 12;
    params.maxCrackLength      = 180;
    params.minAspectRatio      = 6;
    params.minEccentricity     = 0.85;
    params.closeRadius         = 1;
    params.blackHatLength      = 9;

%% ============================================================
% POLYPROPYLENE
%% ============================================================

case 'Polypropylene (PP)'

    params.gaussianSigma       = 0.8;
    params.claheClipLimit      = 0.010;
    params.adaptiveSensitivity = 0.42;
    params.minCrackArea        = 40;
    params.maxCrackArea        = 1000;
    params.minCrackLength      = 12;
    params.maxCrackLength      = 180;
    params.minAspectRatio      = 6;
    params.minEccentricity     = 0.85;
    params.closeRadius         = 1;
    params.blackHatLength      = 9;

%% ============================================================
% POLYCARBONATE
%% ============================================================

case 'Polycarbonate (PC)'

    params.gaussianSigma       = 1.0;
    params.claheClipLimit      = 0.015;
    params.adaptiveSensitivity = 0.45;
    params.minCrackArea        = 50;
    params.maxCrackArea        = 1400;
    params.minCrackLength      = 15;
    params.maxCrackLength      = 220;
    params.minAspectRatio      = 7;
    params.minEccentricity     = 0.88;
    params.closeRadius         = 2;
    params.blackHatLength      = 15;

%% ============================================================
% NYLON
%% ============================================================

case 'Nylon (PA)'

    params.gaussianSigma       = 1.0;
    params.claheClipLimit      = 0.015;
    params.adaptiveSensitivity = 0.45;
    params.minCrackArea        = 50;
    params.maxCrackArea        = 1400;
    params.minCrackLength      = 15;
    params.maxCrackLength      = 220;
    params.minAspectRatio      = 7;
    params.minEccentricity     = 0.88;
    params.closeRadius         = 2;
    params.blackHatLength      = 15;

%% ============================================================
% DEFAULT
%% ============================================================

otherwise

    params.gaussianSigma       = 1.0;
    params.claheClipLimit      = 0.020;
    params.adaptiveSensitivity = 0.50;
    params.minCrackArea        = 80;
    params.maxCrackArea        = 2000;
    params.minCrackLength      = 20;
    params.maxCrackLength      = 250;
    params.minAspectRatio      = 8;
    params.minEccentricity     = 0.90;
    params.closeRadius         = 2;
    params.blackHatLength      = 15;

end

%% ============================================================
% QUALITY MODEL (COMMON DEFAULTS)
%% ============================================================

params.weightDensity    = 35;
params.weightArea       = 25;
params.weightLength     = 15;
params.weightComplexity = 15;
params.weightTexture    = 10;

%% ============================================================
% SEVERITY LIMITS
%% ============================================================

params.lowSeverity      = 15;
params.mediumSeverity   = 35;
params.highSeverity     = 70;

%% ============================================================
% DEFECT LIMITS
%% ============================================================

params.minorCrackCount  = 2;
params.mediumCrackCount = 5;
params.minorAreaRatio   = 0.01;
params.maxCrackDensity = 1e-4;

%% ============================================================
% CRITICAL DEFECT LIMITS
%% ============================================================

params.criticalCrackLength = 120;
params.criticalAreaRatio   = 0.010;
params.criticalCrackCount  = 8;

%% ============================================================
% PARAMETER TOLERANCE
%% ============================================================

params.parameterTolerance = 0.10;

end