%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : getRecommendedParameters.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Provides recommended ultrasonic welding process parameters, including
% weld time, pressure, amplitude, and operating frequency based on the
% selected material type and specimen thickness.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ============================================================
% RECOMMENDED WELD PARAMETERS
%% ============================================================

function [optTime,...
          optPressure,...
          optAmplitude,...
          optFrequency] = ...
    getRecommendedParameters(material,thickness)

switch material

%% ============================================================
% COPPER
%% ============================================================

case 'Copper'

    if thickness <= 0.1

        optTime = 0.20;
        optPressure = 0.18;
        optAmplitude = 70;
        optFrequency = 35;

    elseif thickness <= 0.2

        optTime = 0.28;
        optPressure = 0.22;
        optAmplitude = 75;
        optFrequency = 35;

    elseif thickness <= 0.5

        optTime = 0.35;
        optPressure = 0.25;
        optAmplitude = 85;
        optFrequency = 20;

    elseif thickness <= 1.0

        optTime = 0.50;
        optPressure = 0.35;
        optAmplitude = 95;
        optFrequency = 20;

    else

        optTime = 0.65;
        optPressure = 0.45;
        optAmplitude = 100;
        optFrequency = 20;

    end

%% ============================================================
% ALUMINUM
%% ============================================================

case 'Aluminum'

    if thickness <= 0.2

        optTime = 0.18;
        optPressure = 0.15;
        optAmplitude = 65;
        optFrequency = 35;

    elseif thickness <= 0.5

        optTime = 0.30;
        optPressure = 0.20;
        optAmplitude = 80;
        optFrequency = 20;

    else

        optTime = 0.45;
        optPressure = 0.30;
        optAmplitude = 90;
        optFrequency = 20;

    end

%% ============================================================
% BRASS
%% ============================================================

case 'Brass'

    if thickness <= 0.5

        optTime = 0.35;
        optPressure = 0.25;
        optAmplitude = 85;
        optFrequency = 20;

    else

        optTime = 0.50;
        optPressure = 0.35;
        optAmplitude = 95;
        optFrequency = 20;

    end

%% ============================================================
% STEEL
%% ============================================================

case 'Steel'

    if thickness <= 1.0

        optTime = 0.55;
        optPressure = 0.40;
        optAmplitude = 90;
        optFrequency = 20;

    else

        optTime = 0.75;
        optPressure = 0.55;
        optAmplitude = 100;
        optFrequency = 20;

    end

%% ============================================================
% TITANIUM
%% ============================================================

case 'Titanium'

    if thickness <= 0.5

        optTime = 0.45;
        optPressure = 0.35;
        optAmplitude = 85;
        optFrequency = 20;

    else

        optTime = 0.65;
        optPressure = 0.45;
        optAmplitude = 95;
        optFrequency = 20;

    end

%% ============================================================
% NICKEL
%% ============================================================

case 'Nickel'

    if thickness <= 0.5

        optTime = 0.45;
        optPressure = 0.30;
        optAmplitude = 80;
        optFrequency = 20;

    else

        optTime = 0.60;
        optPressure = 0.40;
        optAmplitude = 90;
        optFrequency = 20;

    end

%% ============================================================
% ABS PLASTIC
%% ============================================================

case 'ABS Plastic'

    if thickness <= 2

        optTime = 0.20;
        optPressure = 0.10;
        optAmplitude = 65;
        optFrequency = 35;

    else

        optTime = 0.35;
        optPressure = 0.18;
        optAmplitude = 75;
        optFrequency = 35;

    end

%% ============================================================
% POLYPROPYLENE
%% ============================================================

case 'Polypropylene (PP)'

    optTime = 0.20;
    optPressure = 0.12;
    optAmplitude = 65;
    optFrequency = 35;

%% ============================================================
% POLYCARBONATE
%% ============================================================

case 'Polycarbonate (PC)'

    optTime = 0.30;
    optPressure = 0.18;
    optAmplitude = 75;
    optFrequency = 35;

%% ============================================================
% NYLON
%% ============================================================

case 'Nylon (PA)'

    optTime = 0.35;
    optPressure = 0.20;
    optAmplitude = 80;
    optFrequency = 35;

%% ============================================================
% DEFAULT
%% ============================================================

otherwise

    optTime = 0.30;
    optPressure = 0.20;
    optAmplitude = 80;
    optFrequency = 20;

end

end