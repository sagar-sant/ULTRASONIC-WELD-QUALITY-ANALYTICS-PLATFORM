%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : ULTRASONIC_WELDING_ANALYZER1.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Implements the graphical user interface (GUI) for the Ultrasonic Weld
% Quality Analytics Platform. It provides user interaction for weld image
% loading, analysis, visualization of inspection results, and automated
% report generation.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 
function ULTRASONIC_WELDING_ANALYZER1

clc;
close all;

%% ============================================================
% THEME
%% ============================================================

theme.bg        = [0.94 0.95 0.97];
theme.panel     = [0.08 0.10 0.18];
theme.card      = [0.18 0.20 0.28];

theme.white     = [1 1 1];

theme.blue      = [0.10 0.55 1.00];
theme.green     = [0.15 0.80 0.45];
theme.orange    = [1.00 0.65 0.10];
theme.red       = [0.90 0.25 0.25];

theme.lightText = [0.85 0.87 0.92];

%% ============================================================
% MAIN WINDOW
%% ============================================================

fig = uifigure;

fig.Name = ...
    'Ultrasonic Weld Quality Analytics Platform';

fig.WindowState = 'maximized';

fig.Color = theme.bg;

%% ============================================================
% APPLICATION STATE
%% ============================================================

app = struct();

% -------------------------------------------------------------
% Image Data
% -------------------------------------------------------------
app.originalImage = [];
app.roiImage = [];
app.analysisResults = [];

% -------------------------------------------------------------
% Session Information
% -------------------------------------------------------------
app.currentFile = "";
app.sessionStart = datetime("now");

% -------------------------------------------------------------
% Application Status
% -------------------------------------------------------------
app.isImageLoaded = false;
app.isAnalyzed = false;

setappdata(fig,'APP',app);

%% ============================================================
% MAIN GRID
%% ============================================================

mainGrid = uigridlayout(fig);

mainGrid.ColumnWidth = ...
{
420
'1x'
380
};

mainGrid.RowHeight = ...
{
110
'1x'
250
};

mainGrid.Padding = [20 20 20 20];

mainGrid.RowSpacing = 10;
mainGrid.ColumnSpacing = 10;

%% ============================================================
% HEADER
%% ============================================================

headerPanel = uipanel(mainGrid);

headerPanel.Layout.Row = 1;
headerPanel.Layout.Column = [1 3];

headerPanel.BackgroundColor = theme.panel;

headerPanel.BorderType = 'none';

headerGrid = uigridlayout(headerPanel);
headerGrid.BackgroundColor = [0.78 0.84 0.92];

headerGrid.RowHeight = {45 20};

headerGrid.ColumnWidth = {'1x'};

titleLabel = uilabel(headerGrid);
titleLabel.Layout.Row = 1;
titleLabel.Layout.Column = 1;

titleLabel.Text = ...
    'ULTRASONIC WELD QUALITY ANALYTICS PLATFORM';

titleLabel.FontSize = 32;

titleLabel.FontColor = [0 0.15 0.50];

titleLabel.FontWeight = 'bold';

titleLabel.HorizontalAlignment = 'center';

subtitleLabel = uilabel(headerGrid);
subtitleLabel.Layout.Row = 2;
subtitleLabel.Layout.Column = 1;

subtitleLabel.Text = ...
    'Inspection & Defect Analysis Dashboard';

subtitleLabel.FontSize = 16;

subtitleLabel.FontColor = [0 0 0];

subtitleLabel.FontWeight = 'bold';

subtitleLabel.HorizontalAlignment = 'center';

%% ============================================================
% CONTROL CENTER
%% ============================================================

leftPanel = uipanel(mainGrid);

leftPanel.Layout.Row = 2;
leftPanel.Layout.Column = 1;

leftPanel.Title = ...
    'CONTROL CENTER';

leftPanel.BackgroundColor = theme.panel;

leftPanel.ForegroundColor = theme.white;

%% ============================================================
% LEFT GRID
%% ============================================================

leftGrid = uigridlayout(leftPanel);

leftGrid.RowHeight = ...
{
135
190
200
};

leftGrid.ColumnWidth = ...
{
'1x'
'1x'
};

leftGrid.Padding = [10 10 10 10];

leftGrid.RowSpacing = 10;
leftGrid.ColumnSpacing = 10;

%% ============================================================
% IMAGE INPUT PANEL
%% ============================================================

inputPanel = uipanel(leftGrid);

inputPanel.Title = 'IMAGE INPUT';

inputPanel.BackgroundColor = theme.card;

inputPanel.ForegroundColor = theme.white;

inputGrid = uigridlayout(inputPanel);

inputGrid.RowHeight = {40 40};

inputGrid.ColumnWidth = ...
{
'1x'
'1x'
};

inputGrid.Padding = [10 10 10 10];

inputGrid.RowSpacing = 8;
inputGrid.ColumnSpacing = 8;

inputPanel.Layout.Row = 1;
inputPanel.Layout.Column = 1;

%% LOAD IMAGE

loadBtn = uibutton(inputGrid,'push');

loadBtn.Text = 'Load Image';

loadBtn.FontWeight = 'bold';

loadBtn.BackgroundColor = theme.blue;

loadBtn.FontColor = theme.white;

loadBtn.Layout.Row = 1;
loadBtn.Layout.Column = 1;

%% CAMERA

cameraBtn = uibutton(inputGrid,'push');

cameraBtn.Text = sprintf('Camera');
cameraBtn.FontWeight = 'bold';
cameraBtn.BackgroundColor = theme.blue;

cameraBtn.FontColor = theme.white;

cameraBtn.Layout.Row = 1;
cameraBtn.Layout.Column = 2;

%% BATCH

batchBtn = uibutton(inputGrid,'push');

batchBtn.Text = 'Batch Folder';

batchBtn.FontWeight = 'bold';

batchBtn.BackgroundColor = theme.blue;

batchBtn.FontColor = theme.white;

batchBtn.Layout.Row = 2;
batchBtn.Layout.Column = 1;

%% EXAMPLES

exampleDropdown = uidropdown(inputGrid);

exampleDropdown.Items = ...
{
'Select Example'
'Crack-Free'
'Non-Extrusion Crack'
'Material Extrusion Crack'
};

exampleDropdown.Layout.Row = 2;
exampleDropdown.Layout.Column = 2;
exampleDropdown.ValueChangedFcn = ...
    @(src,event)loadExampleImage(src.Value);

%% ============================================================
% ANALYSIS CONTROLS
%% ============================================================

analysisPanel = uipanel(leftGrid);

analysisPanel.Title = ...
    'ANALYSIS CONTROLS';

analysisPanel.BackgroundColor = theme.card;

analysisPanel.ForegroundColor = theme.white;

analysisGrid = uigridlayout(analysisPanel);

analysisGrid.RowHeight = ...
{
45
45
45
};

analysisGrid.ColumnWidth = ...
{
'1x'
'1x'
};

analysisGrid.Padding = [10 10 10 10];

analysisGrid.RowSpacing = 8;
analysisGrid.ColumnSpacing = 8;

%% ANALYZE

analyzeBtn = uibutton(analysisGrid,'push');

analyzeBtn.Text = 'Analyze';

analyzeBtn.BackgroundColor = theme.green;

analyzeBtn.FontColor = theme.white;

analyzeBtn.FontWeight = 'bold';

analyzeBtn.Enable = 'off';

analyzeBtn.Layout.Row = 1;
analyzeBtn.Layout.Column = 1;

%% CLEAR

clearBtn = uibutton(analysisGrid,'push');

clearBtn.Text = 'Clear';

clearBtn.Layout.Row = 1;
clearBtn.Layout.Column = 2;

%% PDF

exportPDFBtn = uibutton(analysisGrid,'push');

exportPDFBtn.Text = 'Export PDF';

exportPDFBtn.Layout.Row = 2;
exportPDFBtn.Layout.Column = 1;

%% EXCEL

exportExcelBtn = uibutton(analysisGrid,'push');

exportExcelBtn.Text = 'Export Excel';

exportExcelBtn.Layout.Row = 2;
exportExcelBtn.Layout.Column = 2;

%% HTML

exportHTMLBtn = uibutton(analysisGrid,'push');

exportHTMLBtn.Text = 'Export HTML';

exportHTMLBtn.Layout.Row = 3;
exportHTMLBtn.Layout.Column = [1 2];

analysisPanel.Layout.Row = 1;
analysisPanel.Layout.Column = 2;

%% ============================================================
% WELD PARAMETERS
%% ============================================================

paramPanel = uipanel(leftGrid);

paramPanel.Title = ...
    'WELD PARAMETERS';

paramPanel.BackgroundColor = theme.card;

paramPanel.ForegroundColor = theme.white;

paramGrid = uigridlayout(paramPanel);

paramGrid.RowHeight = ...
{
'fit'
'fit'
'fit'
'fit'
'fit'
'fit'
};

paramGrid.ColumnWidth = ...
{
200
130
};

paramGrid.RowSpacing = 1;
paramGrid.ColumnSpacing = 2;

%% MATERIAL TYPE

uilabel(paramGrid,...
    'Text','Material Type',...
    'FontColor',[0 0 0],...
    'FontWeight','bold');

materialDropdown = uidropdown(paramGrid);

materialDropdown.Items = ...
{
'Copper'
'Aluminum'
'Brass'
'Steel'
'Titanium'
'Nickel'
'ABS Plastic'
'Polypropylene (PP)'
'Polycarbonate (PC)'
'Nylon (PA)'
};

materialDropdown.Value = 'Copper';

%% THICKNESS

thicknessLabel = uilabel(paramGrid);

thicknessLabel.Text = 'Thickness (mm)';
thicknessLabel.FontColor = [0 0 0];
thicknessLabel.FontWeight = 'bold';
thicknessLabel.Layout.Row = 2;
thicknessLabel.Layout.Column = 1;

thicknessDropdown = uidropdown(paramGrid);

thicknessDropdown.Items = ...
{
'0.1'
'0.2'
'0.3'
'0.5'
'1.0'
'2.0'
};

thicknessDropdown.Value = '0.5';

thicknessDropdown.Layout.Row = 2;
thicknessDropdown.Layout.Column = 2;

thicknessDropdown.ValueChangedFcn = ...
    @(~,~)updateMaterialSettings();

%% WELD TIME

uilabel(paramGrid,...
    'Text','Weld Time (s)',...
    'FontColor',[0 0 0], 'FontWeight','bold');

timeField = uieditfield( ...
    paramGrid,...
    'numeric');

timeField.Value = 0.35;

%% PRESSURE

uilabel(paramGrid,...
    'Text','Pressure (MPa)',...
    'FontColor',[0 0 0], 'FontWeight','bold');

pressureField = uieditfield( ...
    paramGrid,...
    'numeric');

pressureField.Value = 0.25;

%% AMPLITUDE

uilabel(paramGrid,...
    'Text','Amplitude (%)', ...
    'FontColor',[0 0 0], 'FontWeight','bold');

amplitudeField = uieditfield( ...
    paramGrid,...
    'numeric');

amplitudeField.Value = 85;

%% FREQUENCY

uilabel(paramGrid,...
    'Text','Frequency (kHz)', ...
    'FontColor',[0 0 0], 'FontWeight','bold');

frequencyField = uieditfield( ...
    paramGrid,...
    'numeric');

frequencyField.Value = 20;

paramPanel.Layout.Row = 2;
paramPanel.Layout.Column = [1 2];


%% ============================================================
% CENTER WORKSPACE
%% ============================================================

centerPanel = uipanel(mainGrid);

centerPanel.Layout.Row = 2;
centerPanel.Layout.Column = 2;

centerPanel.Title = ...
    'IMAGE ANALYSIS WORKSPACE';

centerPanel.BackgroundColor = theme.panel;

centerPanel.ForegroundColor = theme.white;

workspaceGrid = uigridlayout(centerPanel);

workspaceGrid.RowHeight = ...
{
'1x'
'1x'
};

workspaceGrid.ColumnWidth = ...
{
'1x'
'1x'
};

workspaceGrid.Padding = [10 10 10 10];

workspaceGrid.RowSpacing = 10;
workspaceGrid.ColumnSpacing = 10;

%% ============================================================
% ORIGINAL IMAGE
%% ============================================================

originalPanel = uipanel(workspaceGrid);

originalPanel.Title = ...
    'ORIGINAL IMAGE';

originalPanel.BackgroundColor = theme.card;

originalPanel.ForegroundColor = theme.white;

originalPanel.Layout.Row = 1;
originalPanel.Layout.Column = 1;

originalGrid = uigridlayout(originalPanel);

originalGrid.RowHeight = {'1x'};
originalGrid.ColumnWidth = {'1x'};

originalGrid.Padding = [0 0 0 0];
originalGrid.RowSpacing = 0;
originalGrid.ColumnSpacing = 0;

UI.axOriginal = uiaxes(originalGrid);

UI.axOriginal.Layout.Row = 1;
UI.axOriginal.Layout.Column = 1;

UI.axOriginal.Toolbar.Visible = 'off';
UI.axOriginal.Interactions = [];

axis(UI.axOriginal,'off');

%% ============================================================
% ENHANCED IMAGE
%% ============================================================

enhancedPanel = uipanel(workspaceGrid);

enhancedPanel.Title = ...
    'ENHANCED IMAGE';

enhancedPanel.BackgroundColor = theme.card;

enhancedPanel.ForegroundColor = theme.white;

enhancedPanel.Layout.Row = 1;
enhancedPanel.Layout.Column = 2;

enhancedGrid = uigridlayout(enhancedPanel);

enhancedGrid.RowHeight = {'1x'};
enhancedGrid.ColumnWidth = {'1x'};

enhancedGrid.Padding = [0 0 0 0];
enhancedGrid.RowSpacing = 0;
enhancedGrid.ColumnSpacing = 0;

UI.axEnhanced = uiaxes(enhancedGrid);

UI.axEnhanced.Layout.Row = 1;
UI.axEnhanced.Layout.Column = 1;

UI.axEnhanced.Toolbar.Visible = 'off';
UI.axEnhanced.Interactions = [];

%% ============================================================
% OVERLAY PANEL
%% ============================================================

overlayPanel = uipanel(workspaceGrid);

overlayPanel.Title = ...
    'DEFECT VISUALIZATION';

overlayPanel.BackgroundColor = theme.card;

overlayPanel.ForegroundColor = theme.white;

overlayPanel.Layout.Row = 2;
overlayPanel.Layout.Column = 1;

overlayGrid = uigridlayout(overlayPanel);

overlayGrid.RowHeight = {25,'1x'};

overlayGrid.Padding = [0 0 0 0];
overlayGrid.RowSpacing = 2;
overlayGrid.ColumnSpacing = 0;

%% OVERLAY MODE

UI.overlayMode = uidropdown(overlayGrid);

UI.overlayMode.Items = ...
{
'Overlay'
'Heatmap'
'Bounding Boxes'
'Segmentation'
};

UI.overlayMode.Value = 'Overlay';

%% OVERLAY AXES

UI.axOverlay = uiaxes(overlayGrid);

UI.axOverlay.Layout.Row = 2;
UI.axOverlay.Layout.Column = 1;

UI.axOverlay.Toolbar.Visible = 'off';
UI.axOverlay.Interactions = [];

UI.axOverlay.XColor = 'none';
UI.axOverlay.YColor = 'none';

axis(UI.axOverlay,'off');

%% ============================================================
% SEGMENTATION PANEL
%% ============================================================

segmentPanel = uipanel(workspaceGrid);

segmentPanel.Title = ...
    'CRACK SEGMENTATION';

segmentPanel.BackgroundColor = theme.card;

segmentPanel.ForegroundColor = theme.white;

segmentPanel.Layout.Row = 2;
segmentPanel.Layout.Column = 2;

segmentGrid = uigridlayout(segmentPanel);

segmentGrid.RowHeight = {'1x'};
segmentGrid.ColumnWidth = {'1x'};

segmentGrid.Padding = [0 0 0 0];
segmentGrid.RowSpacing = 0;
segmentGrid.ColumnSpacing = 0;

UI.axSegmentation = uiaxes(segmentGrid);

UI.axSegmentation.Layout.Row = 1;
UI.axSegmentation.Layout.Column = 1;

UI.axSegmentation.Toolbar.Visible = 'off';
UI.axSegmentation.Interactions = [];

%% ============================================================
% KPI DASHBOARD
%% ============================================================

rightPanel = uipanel(mainGrid);

rightPanel.Layout.Row = 2;
rightPanel.Layout.Column = 3;

rightPanel.Title = ...
    'QUALITY DASHBOARD';

rightPanel.BackgroundColor = theme.panel;

rightPanel.ForegroundColor = theme.white;

%% ============================================================
% RIGHT GRID
%% ============================================================

rightGrid = uigridlayout(rightPanel);

rightGrid.RowHeight = ...
{
100
100
100
'4x'
};

rightGrid.ColumnWidth = ...
{
'1x'
'1x'
};

rightGrid.Padding = [10 10 10 10];

rightGrid.RowSpacing = 10;

%% ============================================================
% QUALITY SCORE CARD
%% ============================================================

qualityPanel = uipanel(rightGrid);

qualityPanel.Layout.Row = 1;
qualityPanel.Layout.Column = 1;

qualityPanel.Title = 'QUALITY SCORE';

qualityPanel.BackgroundColor = theme.card;

qualityPanel.ForegroundColor = theme.white;

qualityGrid = uigridlayout(qualityPanel);

UI.qualityLabel = uilabel(qualityGrid);

UI.qualityLabel.Text = '0%';

UI.qualityLabel.FontSize = 32;

UI.qualityLabel.FontWeight = 'bold';

UI.qualityLabel.FontColor = theme.green;

UI.qualityLabel.HorizontalAlignment = 'center';

UI.qualityLabel.VerticalAlignment = 'center';

qualityGrid.RowHeight = {'1x'};
qualityGrid.ColumnWidth = {'1x'};

qualityGrid.Padding = [0 0 0 0];
qualityGrid.RowSpacing = 0;
qualityGrid.ColumnSpacing = 0;

%% ============================================================
% CONFIDENCE CARD
%% ============================================================

confidencePanel = uipanel(rightGrid);

confidencePanel.Layout.Row = 1;
confidencePanel.Layout.Column = 2;

confidencePanel.Title = 'CONFIDENCE';

confidencePanel.BackgroundColor = theme.card;

confidencePanel.ForegroundColor = theme.white;

confidenceGrid = uigridlayout(confidencePanel);

UI.confidenceLabel = uilabel(confidenceGrid);

UI.confidenceLabel.Text = '0%';

UI.confidenceLabel.FontSize = 30;

UI.confidenceLabel.FontWeight = 'bold';

UI.confidenceLabel.FontColor = theme.blue;

UI.confidenceLabel.HorizontalAlignment = 'center';

UI.confidenceLabel.VerticalAlignment = 'center';


confidenceGrid.RowHeight = {'1x'};
confidenceGrid.ColumnWidth = {'1x'};

confidenceGrid.Padding = [0 0 0 0];
confidenceGrid.RowSpacing = 0;
confidenceGrid.ColumnSpacing = 0;

%% ============================================================
% CRACK COUNT CARD
%% ============================================================

crackPanel = uipanel(rightGrid);

crackPanel.Layout.Row = 2;
crackPanel.Layout.Column = 1;

crackPanel.Title = 'CRACK COUNT';

crackPanel.BackgroundColor = theme.card;

crackPanel.ForegroundColor = theme.white;

crackGrid = uigridlayout(crackPanel);

UI.crackLabel = uilabel(crackGrid);

UI.crackLabel.Text = '0';

UI.crackLabel.FontSize = 30;

UI.crackLabel.FontWeight = 'bold';

UI.crackLabel.FontColor = theme.orange;

UI.crackLabel.HorizontalAlignment = 'center';

UI.crackLabel.VerticalAlignment = 'center';


crackGrid.RowHeight = {'1x'};
crackGrid.ColumnWidth = {'1x'};

crackGrid.Padding = [0 0 0 0];
crackGrid.RowSpacing = 0;
crackGrid.ColumnSpacing = 0;

%% ============================================================
% SEVERITY CARD
%% ============================================================

severityPanel = uipanel(rightGrid);

severityPanel.Layout.Row = 2;
severityPanel.Layout.Column = 2;

severityPanel.Title = 'SEVERITY';

severityPanel.BackgroundColor = theme.card;

severityPanel.ForegroundColor = theme.white;

severityGrid = uigridlayout(severityPanel);

UI.severityLabel = uilabel(severityGrid);

UI.severityLabel.Text = 'WAITING';

UI.severityLabel.FontSize = 22;

UI.severityLabel.FontWeight = 'bold';

UI.severityLabel.HorizontalAlignment = 'center';

UI.severityLabel.VerticalAlignment = 'center';

severityGrid.RowHeight = {'1x'};
severityGrid.ColumnWidth = {'1x'};

severityGrid.Padding = [0 0 0 0];
severityGrid.RowSpacing = 0;
severityGrid.ColumnSpacing = 0;

%% ============================================================
% STATUS CARD
%% ============================================================

statusPanel = uipanel(rightGrid);

statusPanel.Layout.Row = 3;
statusPanel.Layout.Column = [1 2];

statusPanel.Title = 'STATUS';

statusPanel.BackgroundColor = theme.card;

statusPanel.ForegroundColor = theme.white;

statusGrid = uigridlayout(statusPanel);

UI.statusLabel = uilabel(statusGrid);

UI.statusLabel.Text = 'READY';

UI.statusLabel.FontSize = 24;

UI.statusLabel.FontWeight = 'bold';

UI.statusLabel.HorizontalAlignment = 'center';

UI.statusLabel.VerticalAlignment = 'center';

statusGrid.RowHeight = {'1x'};
statusGrid.ColumnWidth = {'1x'};

statusGrid.Padding = [0 0 0 0];
statusGrid.RowSpacing = 0;
statusGrid.ColumnSpacing = 0;


%% ============================================================
% RECOMMENDATION PANEL
%% ============================================================

recommendationPanel = uipanel(mainGrid);

recommendationPanel.Layout.Row = 3;
recommendationPanel.Layout.Column = [1 2];

recommendationPanel.Title = ...
    'AI RECOMMENDATIONS';

recommendationPanel.BackgroundColor = theme.panel;

recommendationPanel.ForegroundColor = theme.white;

recommendationGrid = uigridlayout(recommendationPanel);

recommendationGrid.RowHeight = {'2x'};
recommendationGrid.ColumnWidth = {'1x'};

recommendationGrid.Padding = [5 5 5 5];

recommendationGrid.RowSpacing = 0;
recommendationGrid.ColumnSpacing = 0;

UI.recommendationText = ...
    uitextarea(recommendationGrid);

UI.recommendationText.Layout.Row = 1;
UI.recommendationText.Layout.Column = 1;

UI.recommendationText.Editable = 'off';

UI.recommendationText.FontName = 'Consolas';

UI.recommendationText.FontSize = 12;

UI.recommendationText.FontColor = [0.1 0.1 0.1];

UI.recommendationText.BackgroundColor = [0.98 0.98 0.99];

UI.recommendationText.Value = ...
{
'================================================'
' AI WELD ASSESSMENT REPORT'
'================================================'
''
'System Status: READY'
''
'Awaiting image upload and analysis.'
''
'Workflow:'
'1. Load Image'
'2. Configure Weld Parameters'
'3. Click Analyze'
'4. Review Inspection Report'
};

%% ============================================================
% ANALYSIS METRICS PANEL
%% ============================================================

analysisPanel = uipanel(mainGrid);

analysisPanel.Layout.Row = 3;
analysisPanel.Layout.Column = 3;

analysisPanel.Title = ...
    'ANALYSIS METRICS';

analysisPanel.BackgroundColor = theme.panel;

analysisPanel.ForegroundColor = theme.white;

analysisGrid = ...
    uigridlayout(analysisPanel);

analysisGrid.RowHeight = {'1x'};
analysisGrid.ColumnWidth = {'1x'};

analysisGrid.Padding = [5 5 5 5];

analysisGrid.RowSpacing = 0;
analysisGrid.ColumnSpacing = 0;

UI.resultsTable = ...
    uitable(analysisGrid);

UI.resultsTable.ColumnName = ...
{
'Metric','Value'
};

UI.resultsTable.ColumnWidth = ...
{
150,230
};

UI.resultsTable.FontSize = 11;

UI.resultsTable.Data = {};

%% ============================================================
% STORE UI HANDLES
%% ============================================================

UI.fig = fig;

UI.loadBtn = loadBtn;
UI.cameraBtn = cameraBtn;
UI.batchBtn = batchBtn;

UI.analyzeBtn = analyzeBtn;
UI.clearBtn = clearBtn;

UI.exportPDFBtn = exportPDFBtn;
UI.exportExcelBtn = exportExcelBtn;
UI.exportHTMLBtn = exportHTMLBtn;

UI.exampleDropdown = exampleDropdown;

UI.materialDropdown = materialDropdown;
UI.thicknessDropdown = thicknessDropdown;

UI.timeField = timeField;
UI.pressureField = pressureField;
UI.amplitudeField = amplitudeField;
UI.frequencyField = frequencyField;

setappdata(fig,'UI',UI);

%% ============================================================
% CALLBACK REGISTRATION
%% ============================================================

loadBtn.ButtonPushedFcn = ...
    @(~,~)loadImage();

cameraBtn.ButtonPushedFcn = ...
    @(~,~)captureFromCamera();

analyzeBtn.ButtonPushedFcn = ...
    @(~,~)runAnalysis();

batchBtn.ButtonPushedFcn = ...
    @(~,~)batchAnalyze();

clearBtn.ButtonPushedFcn = ...
    @(~,~)clearSession();

exportPDFBtn.ButtonPushedFcn = ...
    @(~,~)exportPDF();

exportExcelBtn.ButtonPushedFcn = ...
    @(~,~)exportExcel();

exportHTMLBtn.ButtonPushedFcn = ...
    @(~,~)exportHTML();

UI.overlayMode.ValueChangedFcn = ...
    @(~,~)updateOverlayView();

materialDropdown.ValueChangedFcn = ...
    @(~,~)updateMaterialSettings();

%% ============================================================
% MATERIAL SETTINGS
%% ============================================================

function updateMaterialSettings()

    material = UI.materialDropdown.Value;

    thickness = str2double( ...
               UI.thicknessDropdown.Value);

    [optTime,...
     optPressure,...
     optAmplitude,...
     optFrequency] = ...
        getRecommendedParameters( ...
        material,...
        thickness);

                UI.timeField.Value = optTime;
                UI.pressureField.Value = optPressure;
                UI.amplitudeField.Value = optAmplitude;
                UI.frequencyField.Value = optFrequency;

end

%% ============================================================
% LOAD IMAGE
%% ============================================================

function loadImage()

    [file,path] = uigetfile( ...
        {'*.jpg;*.jpeg;*.png;*.bmp',...
        'Image Files'});

    if isequal(file,0)
        return;
    end

    img = imread(fullfile(path,file));

    app = getappdata(fig,'APP');

    app.originalImage = img;
    app.currentFile = string(fullfile(path,file));

    app.isImageLoaded = true;
    app.isAnalyzed = false;

    setappdata(fig,'APP',app);

    imshow(img,...
        'Parent',UI.axOriginal,...
        'InitialMagnification','fit');

    axis(UI.axOriginal,'image');
    axis(UI.axOriginal,'off');

    UI.analyzeBtn.Enable = 'on';

end

%% ============================================================
% BATCH ANALYSIS
%% ============================================================

function batchAnalyze()

folder = uigetdir();

if isequal(folder,0)
    return;
end

files = [ ...
    dir(fullfile(folder,'*.jpg'));
    dir(fullfile(folder,'*.png'));
    dir(fullfile(folder,'*.jpeg'));
    dir(fullfile(folder,'*.bmp'))];

if isempty(files)

    uialert(fig,...
        'No images found.',...
        'Batch');

    return;

end

d = uiprogressdlg(fig,...
    'Title','Batch Analysis',...
    'Message','Processing images...');

resultsTable = cell(length(files),5);

for k = 1:length(files)

    d.Value = k/length(files);

    d.Message = sprintf( ...
        'Processing %d of %d',...
        k,length(files));

    img = imread(fullfile(folder,files(k).name));

    [roi,~,ok] = detectWeldROI(img);

    if ~ok
        roi = img;
    end

    results = ADVANCED_WELD_ANALYSIS1( ...
        roi,...
        UI.timeField.Value,...
        UI.pressureField.Value,...
        UI.amplitudeField.Value,...
        UI.materialDropdown.Value,...
        str2double(UI.thicknessDropdown.Value));

    resultsTable{k,1} = files(k).name;
    resultsTable{k,2} = results.status;
    resultsTable{k,3} = results.qualityScore;
    resultsTable{k,4} = results.confidence;
    resultsTable{k,5} = results.crackCount;

end

close(d);

T = cell2table(resultsTable,...
    'VariableNames',...
    {'Image','Status','Quality','Confidence','Cracks'});

[file,path] = uiputfile(...
    '*.xlsx',...
    'Save Batch Report');

if isequal(file,0)
    return;
end

writetable(T,fullfile(path,file));

uialert(fig,...
    'Batch analysis completed.',...
    'IWLE');

end

%% ============================================================
% CAMERA ACQUISITION
%
% Captures a weld image directly from the connected webcam.
%% ============================================================

function captureFromCamera()

    try
        cam = webcam;
    catch
        uialert(fig,...
            'No camera detected.',...
            'Camera');
        return;
    end

    previewFig = uifigure(...
        'Name','Live Camera',...
        'Position',[250 150 800 600]);

    ax = uiaxes(previewFig);

    ax.Position = [20 80 760 500];

    img = snapshot(cam);

    imshow(img,'Parent',ax);

    captureBtn = uibutton(previewFig,...
        'Text','Capture',...
        'Position',[350 20 100 40]);

    captureBtn.ButtonPushedFcn = @captureImage;

    %===========================================================
    % Capture Callback
    %===========================================================

    function captureImage(~,~)

        img = snapshot(cam);

        close(previewFig);

        clear cam;

        currentImage = img;

        %% UPDATE APPLICATION STATE

        app = getappdata(fig,'APP');

        app.originalImage = currentImage;
        app.currentFile = "Camera Capture";
        app.isImageLoaded = true;
        app.isAnalyzed = false;

        setappdata(fig,'APP',app);

        %% SHARE IMAGE

        setappdata(0,'IWLE_CurrentImage',currentImage);

        %% DISPLAY IMAGE

        imshow(currentImage,...
            'Parent',UI.axOriginal,...
            'InitialMagnification','fit');

        axis(UI.axOriginal,'image');
        axis(UI.axOriginal,'off');

        %% ENABLE ANALYSIS

        UI.analyzeBtn.Enable = 'on';

        %% LOG

        logMessage('Image captured from camera.');

    end

end

%% ============================================================
% RUN ANALYSIS
%% ============================================================

function runAnalysis()

    app = getappdata(fig,'APP');

    if isempty(app.originalImage)

        uialert(fig,...
            'Load an image first.',...
            'No Image');

        return;

    end

    d = uiprogressdlg(fig,...
        'Title','Analyzing Weld',...
        'Message','Processing image...', ...
        'Indeterminate','off');

    d.Value = 0.10;

    drawnow;

    img = app.originalImage;

%% ============================================================
% ROI DETECTION
%% ============================================================

[croppedImg,...
 ~,...
 success] = ...
    detectWeldROI(img);

%% ------------------------------------------------------------
% Automatic ROI Successful
%% ------------------------------------------------------------

if success

    d.Message = ...
        'Automatic weld detection successful...';

    drawnow;

else

    %% --------------------------------------------------------
    % Manual ROI Selection
    %% --------------------------------------------------------

    roiFig = figure( ...
        'Name','Select Weld Region');

    imshow(img);

    title({ ...
    'Automatic detection failed.'; ...
    'Draw ROI Around Weld and Double-Click'});

    roi = drawrectangle();

    try

        wait(roi);

        pos = roi.Position;

    catch

        if isvalid(roiFig)
            close(roiFig);
        end

        close(d);
        return;

    end

    if isempty(pos) || ...
       pos(3) < 5 || ...
       pos(4) < 5

        uialert( ...
            fig,...
            'Please select a valid ROI.',...
            'ROI Error');

        if isvalid(roiFig)
            close(roiFig);
        end

        close(d);
        return;

    end

    croppedImg = ...
        imcrop(img,pos);

    if isvalid(roiFig)
        close(roiFig);
    end

    if isempty(croppedImg)

        uialert( ...
            fig,...
            'ROI selection failed.',...
            'ROI Error');

        close(d);
        return;

    end

    targetHeight = 700;

    scaleFactor = ...
        targetHeight / ...
        size(croppedImg,1);

    croppedImg = ...
        imresize( ...
        croppedImg,...
        scaleFactor,...
        'bicubic');

end

    %% PARAMETERS

    weldTime = ...
        UI.timeField.Value;

    pressure = ...
        UI.pressureField.Value;

    amplitude = ...
        UI.amplitudeField.Value;

    frequency = ...
        UI.frequencyField.Value;

    material = ...
        UI.materialDropdown.Value;

    thickness = str2double( ...
        UI.thicknessDropdown.Value);

%% ------------------------------------------------------------
% IWLE Metadata
%% ------------------------------------------------------------

metadata = struct();

metadata.WeldTime = weldTime;
metadata.Pressure = pressure;
metadata.Amplitude = amplitude;
metadata.Frequency = frequency;
metadata.Material = material;
metadata.Thickness = thickness;

    %% ANALYSIS

    results = ADVANCED_WELD_ANALYSIS1( ...
                    croppedImg,...
                    weldTime,...
                    pressure,...
                    amplitude,...
                    material,...
                    thickness);

    %% Pass complete analysis to IWLE
    metadata.Analysis = results;

%% ------------------------------------------------------------
% Intelligent Weld Learning Engine
%% ------------------------------------------------------------

try

    AI = IWLE_Core( ...
            croppedImg,...
            metadata,...
            "inspect");

    % MERGE AI RESULTS

    results.AI = AI;

catch ME

    disp("======================================");
    disp("IWLE ERROR");
    disp("======================================");

    disp(getReport(ME,'extended'));

    rethrow(ME);

end

    results.material = material;
    results.thickness = thickness;

    results.currentTime = weldTime;

    results.currentPressure = pressure;

    results.currentAmplitude = amplitude;

    results.currentFrequency = ...
    frequency;

   [results.materialScore,...
        results.optTime,...
        results.optPressure,...
        results.optAmplitude,...
        results.optFrequency] = ...
    calculateMaterialScore( ...
            material,...
            thickness,...
            weldTime,...
            pressure,...
            amplitude);

    d.Value = 0.80;

    drawnow;

    app.analysisResults = results;
    app.roiImage = croppedImg;

    app.isAnalyzed = true;

    setappdata(fig,'APP',app);

%% ============================================================
% SHARE ANALYSIS WITH AI ENGINE
%% ============================================================

setappdata(0,'IWLE_LastROI',croppedImg);

setappdata(0,'IWLE_LastMetadata',metadata);

setappdata(0,'IWLE_LastResults',results);

setappdata(0,'IWLE_LastAnalysisTime',datetime("now"));

    %% UPDATE DASHBOARD

    updateDashboard(results);

    d.Value = 1.0;

    pause(0.25);

    close(d);

end

%% ============================================================
% UPDATE DASHBOARD
%% ============================================================

function updateDashboard(results)

    %% ORIGINAL

    hOrig = imshow(results.originalImage,...
    'Parent',UI.axOriginal,...
    'Border','tight');

    hOrig.ButtonDownFcn = @(~,~) ...
    openImageWindow( ...
    results.originalImage,...
    'Original Image');

    %% ENHANCED

    hEnh = imshow(results.enhancedImage,...
    'Parent',UI.axEnhanced,...
    'Border','tight');

    hEnh.ButtonDownFcn = @(~,~) ...
    openImageWindow( ...
    results.enhancedImage,...
    'Enhanced Image');

    axis(UI.axEnhanced,'off');

    %% OVERLAY

    updateOverlayView();

    %% SEGMENTATION

    segDisplay = uint8(results.crackMap) * 255;

    hSeg = imshow(segDisplay,...
    'Parent',UI.axSegmentation,...
    'Border','tight');

    hSeg.ButtonDownFcn = @(~,~) ...
    openImageWindow( ...
    segDisplay,...
    'Crack Segmentation');
    colormap(UI.axSegmentation,gray);

    axis(UI.axSegmentation,'off');

    %% CONFIDENCE PERCENTAGE

    if results.confidence <= 1

        confidencePct = ...
            results.confidence * 100;

    else

        confidencePct = ...
            results.confidence;

    end
    %% KPI CARDS

    UI.qualityLabel.Text = ...
        sprintf('%.0f%%', ...
        results.qualityScore);

%% ============================================================
% AI CONFIDENCE
%% ============================================================

if isfield(results,'AI') && ...
        isfield(results.AI,'Confidence') && ...
        results.AI.Confidence > 0

    UI.confidenceLabel.Text = ...
        sprintf('%.0f%%', ...
        results.AI.Confidence);

else

    UI.confidenceLabel.Text = ...
        sprintf('%.0f%%', ...
        confidencePct);

end

    UI.crackLabel.Text = ...
        num2str(results.crackCount);

    UI.severityLabel.Text = ...
        results.severity;

    switch upper(results.severity)

        case {'LOW','GOOD'}
            UI.severityLabel.FontColor = [0.00 0.60 0.00];

        case {'MODERATE','MEDIUM'}
            UI.severityLabel.FontColor = [0.85 0.55 0.00];

        case 'HIGH'
            UI.severityLabel.FontColor = [0.85 0.25 0.00];

        otherwise
            UI.severityLabel.FontColor = [0.80 0.00 0.00];

     end

    UI.statusLabel.Text = ...
        results.status;

    %% COLOR STATUS

    if strcmpi(results.status,'GOOD')

    UI.statusLabel.FontColor = ...
        theme.green;

    elseif strcmpi(results.status,'ACCEPTABLE')

        UI.statusLabel.FontColor = ...
            theme.orange;

    elseif strcmpi(results.status,'DEFECTIVE')

        UI.statusLabel.FontColor = ...
            theme.red;

    else

        UI.statusLabel.FontColor = ...
            [0 0 0];

    end

%% ============================================================
% ANALYSIS METRICS
%% ============================================================

metrics = {

'Material', char(string(results.material))

'Thickness', sprintf('%.1f mm',results.thickness)

'Parameter Score', sprintf('%.0f %%',results.materialScore)

'Current Frequency', sprintf('%.0f kHz',results.currentFrequency)

'Recommended Frequency', sprintf('%.0f kHz',results.optFrequency)

'Quality Score', sprintf('%.2f',results.qualityScore)

'Confidence',sprintf('%.2f %%',confidencePct)

'Crack Count',results.crackCount

'Severity Index',sprintf('%.2f',results.severityIndex)

'Shape Complexity',sprintf('%.2f',results.shapeComplexity)

'Severity', char(string(results.severity))

'Status', char(string(results.status))

'Defect Type', char(string(results.defectType))

'Area Ratio',sprintf('%.4f',results.areaRatio)

'Max Length',sprintf('%.2f',results.maxLength)

};

%% ============================================================
% AI METRICS
%% ============================================================

if isfield(results,'AI')

    AI = results.AI;

    if isfield(AI,'Prediction')

        metrics(end+1,:) = ...
        {'AI Prediction',char(string(AI.Prediction))};

    end

    if isfield(AI,'Confidence')

        metrics(end+1,:) = ...
        {'AI Confidence',...
        sprintf('%.1f %%', AI.Confidence)};

    end

    if isfield(AI,'SimilarityScore')

        metrics(end+1,:) = ...
        {'Similarity',...
        sprintf('%.1f %%',100*AI.SimilarityScore)};

    end

    if isfield(AI,'AnomalyScore')

        metrics(end+1,:) = ...
        {'Anomaly Score',...
        sprintf('%.3f',AI.AnomalyScore)};

    end

    if isfield(AI,'NearestRecord')

        metrics(end+1,:) = ...
        {'Nearest Record',...
        num2str(AI.NearestRecord)};

    end

end

UI.resultsTable.Data = metrics;

%% RECOMMENDATIONS

recommendations = {};

recommendations{end+1} = ...
'========================================================';

recommendations{end+1} = ...
'        AI WELD ASSESSMENT REPORT';

recommendations{end+1} = ...
'========================================================';

recommendations{end+1} = ...
['Inspection Time : ' ...
char(datetime("now","Format","dd-MMM-yyyy HH:mm:ss"))];

recommendations{end+1} = ...
['Material        : ' char(string(results.material))];

recommendations{end+1} = ...
sprintf('Thickness      : %.1f mm',results.thickness);

recommendations{end+1} = ...
' ';

%% ============================================================
% AI MODEL RESULTS
%% ============================================================

recommendations{end+1} = ...
'========================================================';

recommendations{end+1} = ...
'1. MACHINE LEARNING ASSESSMENT';

recommendations{end+1} = ...
'========================================================';

%% Prediction

if isfield(results,'AI')

    AI = results.AI;

    recommendations{end+1} = ...
        ['Prediction      : ' char(string(AI.Prediction))];

    recommendations{end+1} = ...
        sprintf('Confidence     : %.1f %%',AI.Confidence);

    if isfield(AI,'AnomalyScore')

        recommendations{end+1} = ...
            sprintf('Anomaly Score  : %.3f',AI.AnomalyScore);

    end

    if isfield(AI,'SimilarityScore')

        recommendations{end+1} = ...
            sprintf('Similarity     : %.1f %%', ...
            100*AI.SimilarityScore);

    end

    if isfield(AI,'NearestRecord')

    recommendations{end+1} = ...
        sprintf('Nearest Learned Weld : #%d', AI.NearestRecord);

    end

end

recommendations{end+1}=' ';

recommendations{end+1} = ...
'========================================================';

recommendations{end+1} = ...
'2. IMAGE ANALYSIS';

recommendations{end+1} = ...
'========================================================';

recommendations{end+1} = ...
'Inspection Results';

recommendations{end+1} = ...
'----------------------------------------';

recommendations{end+1} = ...
['Rule-Based Status : ' char(string(results.status))];

recommendations{end+1} = ...
sprintf('Quality Score    : %.1f %%',results.qualityScore);

recommendations{end+1} = ...
sprintf('Confidence       : %.1f %%',confidencePct);

recommendations{end+1}='';

recommendations{end+1}='Defect Analysis';

recommendations{end+1}='----------------------------------------';

recommendations{end+1}=...
['Defect Type      : ' char(string(results.defectType))];

recommendations{end+1}=...
['Severity         : ' char(string(results.severity))];

recommendations{end+1}=...
sprintf('Crack Count      : %d',results.crackCount);

if isfield(results,'fractureDetected')

    recommendations{end+1}=...
    sprintf('Fracture Count   : %d',results.fractureCount);

end

recommendations{end+1}=...
sprintf('Maximum Crack    : %.2f px',results.maxLength);

recommendations{end+1}=...
sprintf('Area Ratio       : %.4f',results.areaRatio);

recommendations{end+1}=...
sprintf('Severity Index   : %.2f',results.severityIndex);

recommendations{end+1}=...
sprintf('Shape Complexity : %.2f',results.shapeComplexity);

recommendations{end+1}=' ';

recommendations{end+1}='Process Assessment';

recommendations{end+1}='----------------------------------------';

recommendations{end+1}=...
['Material         : ' char(string(results.material))];

recommendations{end+1}=...
sprintf('Thickness       : %.1f mm',results.thickness);

recommendations{end+1}=...
sprintf('Current Time    : %.2f s',results.currentTime);

recommendations{end+1}=...
sprintf('Current Pressure: %.2f MPa',results.currentPressure);

recommendations{end+1}=...
sprintf('Amplitude       : %.0f %%',results.currentAmplitude);

recommendations{end+1}=...
sprintf('Frequency       : %.0f kHz',results.currentFrequency);

recommendations{end+1}=...
sprintf('Parameter Match : %.0f %%',results.materialScore);

recommendations{end+1}=' ';

recommendations{end+1}='Engineering Interpretation';

recommendations{end+1}='----------------------------------------';

switch upper(string(results.status))

    case "GOOD"

        recommendations{end+1}=...
        '• Weld quality satisfies inspection criteria.';

        recommendations{end+1}=...
        '• No significant surface defects detected.';

        recommendations{end+1}=...
        '• Geometry appears consistent.';

    case "ACCEPTABLE"

        recommendations{end+1}=...
        '• Minor defects were detected.';

        recommendations{end+1}=...
        '• Weld remains within acceptable limits.';

        recommendations{end+1}=...
        '• Continue production with increased monitoring.';

    case "DEFECTIVE"

        recommendations{end+1}=...
        '• Critical defects detected.';

        recommendations{end+1}=...
        '• Weld integrity may be compromised.';

        recommendations{end+1}=...
        '• Immediate corrective action is recommended.';

end

recommendations{end+1}=' ';

recommendations{end+1}='Root Cause Analysis';

recommendations{end+1}='----------------------------------------';

rootCauseFound = false;

if results.materialScore < 80

    rootCauseFound = true;

    recommendations{end+1}=...
    '• Welding parameters deviate from recommended values.';

end

if results.crackCount > 0

    rootCauseFound = true;

    recommendations{end+1}=...
    '• Surface cracking contributed to quality reduction.';

end

if isfield(results,'fractureDetected') && results.fractureDetected

    rootCauseFound = true;

    recommendations{end+1}=...
    '• Fracture propagation detected.';

end

if results.areaRatio > 0.03

    rootCauseFound = true;

    recommendations{end+1}=...
    '• Large defect area observed.';

end

if results.maxLength > 30

    rootCauseFound = true;

    recommendations{end+1}=...
    '• Long crack indicates unstable welding conditions.';

end

if ~rootCauseFound

    recommendations{end+1}=...
    '• No significant process-related root causes detected.';

end

recommendations{end+1}=' ';

recommendations{end+1} = ...
'========================================================';

recommendations{end+1} = ...
'3. FINAL DECISION';

recommendations{end+1} = ...
'========================================================';

if isfield(results,'AI')

    AI = results.AI;

    recommendations{end+1} = ...
        ['Rule-Based : ' char(string(results.status))];

    recommendations{end+1} = ...
        ['Random Forest : ' char(string(AI.Prediction))];

    if strcmpi(results.status,AI.Prediction)

    recommendations{end+1}=...
    'Agreement      : YES';

    else

    recommendations{end+1}=...
    'Agreement      : NO';

    
    end
    recommendations{end+1}='';

    ruleStatus = upper(string(results.status));
    aiStatus   = upper(string(AI.Prediction));

    if ruleStatus == "GOOD" && aiStatus == "GOOD"

        recommendations{end+1}=...
        'Overall Decision : GOOD';

    elseif (ruleStatus == "GOOD" && aiStatus == "ACCEPTABLE") || ...
           (ruleStatus == "ACCEPTABLE" && aiStatus == "GOOD") || ...
           (ruleStatus == "ACCEPTABLE" && aiStatus == "ACCEPTABLE")

        recommendations{end+1}=...
        'Overall Decision : ACCEPT';

    elseif ruleStatus == "DEFECTIVE" && aiStatus == "DEFECTIVE"

        recommendations{end+1}=...
        'Overall Decision : REJECT';

    else

        recommendations{end+1}=...
        'Overall Decision : MANUAL REVIEW REQUIRED';

    end

end

recommendations{end+1}=' ';


recommendations{end+1} = ...
    'INSPECTION SUMMARY';

recommendations{end+1} = ...
    '--------------------------------';

%% ============================================================
% TOTAL DETECTED DEFECTS
%% ============================================================

detectedDefects = results.crackCount;

if isfield(results,'fractureDetected') && results.fractureDetected

    detectedDefects = detectedDefects + results.fractureCount;

end

recommendations{end+1} = ...
    ['Detected Defects: ' ...
    num2str(detectedDefects)];

recommendations{end+1} = ...
    ['Maximum Crack Length: ' ...
    sprintf('%.2f px',results.maxLength)];

recommendations{end+1} = ...
    ['Defect Area Ratio: ' ...
    sprintf('%.4f',results.areaRatio)];

recommendations{end+1} = ' ';

recommendations{end+1} = ...
'4. PARAMETER OPTIMIZATION';

recommendations{end+1} = ...
    '--------------------------------';

if results.materialScore >= 95

    recommendations{end+1} = ...
        '✓ Parameters are near optimal';

elseif results.materialScore >= 80

    recommendations{end+1} = ...
        '• Minor parameter adjustments recommended';

elseif results.materialScore >= 60

    recommendations{end+1} = ...
        '⚠ Parameters deviate from recommended values';

else

    recommendations{end+1} = ...
        '✖ Significant deviation from recommended settings';

end

recommendations{end+1} = ' ';

%% WELD TIME CORRECTION

timeDiff = ...
    results.optTime - results.currentTime;

if abs(timeDiff) > 0.05

    if timeDiff > 0

        recommendations{end+1} = ...
            ['• Increase Weld Time by ' ...
            num2str(abs(timeDiff),'%.2f') ...
            ' s'];

    else

        recommendations{end+1} = ...
            ['• Reduce Weld Time by ' ...
            num2str(abs(timeDiff),'%.2f') ...
            ' s'];

    end

end

%% PRESSURE CORRECTION

pressureDiff = ...
    results.optPressure - ...
    results.currentPressure;

if abs(pressureDiff) > 0.02

    if pressureDiff > 0

        recommendations{end+1} = ...
            ['• Increase Pressure by ' ...
            num2str(abs(pressureDiff),'%.2f') ...
            ' MPa'];

    else

        recommendations{end+1} = ...
            ['• Reduce Pressure by ' ...
            num2str(abs(pressureDiff),'%.2f') ...
            ' MPa'];

    end

end

%% AMPLITUDE CORRECTION

ampDiff = ...
    results.optAmplitude - ...
    results.currentAmplitude;

if abs(ampDiff) > 3

    if ampDiff > 0

        recommendations{end+1} = ...
            ['• Increase Amplitude by ' ...
            num2str(round(abs(ampDiff))) ...
            '%'];

    else

        recommendations{end+1} = ...
            ['• Reduce Amplitude by ' ...
            num2str(round(abs(ampDiff))) ...
            '%'];

    end

end

%% FREQUENCY RECOMMENDATION

if isfield(results,'currentFrequency')

    freqDiff = ...
        results.optFrequency - ...
        results.currentFrequency;

    if abs(freqDiff) > 1

        recommendations{end+1} = ...
            ['• Recommended Frequency: ' ...
            num2str(results.optFrequency) ...
            ' kHz'];

    else

        recommendations{end+1} = ...
            ['✓ Frequency optimal (' ...
            num2str(results.currentFrequency) ...
            ' kHz)'];

    end

end

recommendations{end+1} = ' ';

recommendations{end+1} = ...
 '5. MATERIAL RECOMMENDATIONS';

recommendations{end+1} = ...
    '--------------------------------';

switch results.material

    case 'Copper'

        recommendations{end+1} = ...
            '• Recommended Frequency: 20 kHz';

        recommendations{end+1} = ...
            '• Recommended Amplitude: 85%';

        recommendations{end+1} = ...
            '• Suitable for battery tabs and busbars';

    case 'Aluminum'

        recommendations{end+1} = ...
            '• Recommended Frequency: 20 kHz';

        recommendations{end+1} = ...
            '• Lower pressure typically improves weld consistency';

    case 'Steel'

        recommendations{end+1} = ...
            '• High amplitude generally required';

        recommendations{end+1} = ...
            '• Verify horn wear regularly';

    case 'Titanium'

        recommendations{end+1} = ...
            '• Use controlled pressure';

        recommendations{end+1} = ...
            '• Monitor heat buildup';

    case 'ABS Plastic'

        recommendations{end+1} = ...
            '• Preferred Frequency: 35 kHz';

        recommendations{end+1} = ...
            '• Avoid excessive pressure';

    otherwise

        recommendations{end+1} = ...
            '• Follow validated welding procedure';

end

recommendations{end+1} = ' ';

recommendations{end+1} = ...
sprintf('Material Compatibility : %.0f %%', ...
results.materialScore);

recommendations{end+1} = ' ';

recommendations{end+1} = ...
    '6. ENGINEERING RECOMMENDATIONS';

recommendations{end+1} = ...
    '--------------------------------';

switch upper(string(results.status))

    case "GOOD"

        recommendations{end+1} = ...
            '✓ Weld quality is good';

        recommendations{end+1} = ...
            '✓ No corrective action required';

        recommendations{end+1} = ...
            '✓ Continue normal production';

    case "ACCEPTABLE"

        recommendations{end+1} = ...
            '• Minor defects detected';

        recommendations{end+1} = ...
            '• Continue production with monitoring';

        recommendations{end+1} = ...
            '• Increase inspection frequency';

    case "DEFECTIVE"

        recommendations{end+1} = ...
            '✖ Weld rejection recommended';

        recommendations{end+1} = ...
            '✖ Immediate process correction required';

        recommendations{end+1} = ...
            '✖ Stop production and inspect the weld process';

        recommendations{end+1} = ...
            '✖ Inspect tooling, alignment and welding parameters';

    otherwise

        recommendations{end+1} = ...
            '• Manual inspection required';

end

recommendations{end+1}=' ';

recommendations{end+1}=...
'========================================================';

recommendations{end+1}=...
'End of AI Weld Assessment Report';

recommendations{end+1}=...
'========================================================';

%% COLOR CODE RECOMMENDATION PANEL

switch upper(string(results.status))

    case "GOOD"
        UI.recommendationText.BackgroundColor = [0.80 1.00 0.80];

    case "ACCEPTABLE"
        UI.recommendationText.BackgroundColor = [1.00 0.90 0.70];

    case "DEFECTIVE"
        UI.recommendationText.BackgroundColor = [1.00 0.70 0.70];

    otherwise
        UI.recommendationText.BackgroundColor = [0.98 0.98 0.99];

end

%% UPDATE REPORT

recommendations = recommendations(:);

UI.recommendationText.Value = ...
    recommendations;
end
%% ============================================================
% OVERLAY SWITCHING
%% ============================================================

function updateOverlayView()

    app = getappdata(fig,'APP');

    if isempty(app.analysisResults)
        return;
    end

    results = ...
        app.analysisResults;

    mode = ...
        UI.overlayMode.Value;

    switch mode

    case 'Overlay'

        hOverlay = imshow( ...
            results.overlayImage,...
            'Parent',UI.axOverlay,...
            'InitialMagnification','fit');

        hOverlay.ButtonDownFcn = @(~,~) ...
            openImageWindow( ...
            results.overlayImage,...
            'Defect Visualization');

    case 'Heatmap'

        hOverlay = imshow( ...
            results.heatmapImage,...
            'Parent',UI.axOverlay,...
            'InitialMagnification','fit');

        hOverlay.ButtonDownFcn = @(~,~) ...
            openImageWindow( ...
            results.heatmapImage,...
            'Heatmap View');

    case 'Bounding Boxes'

        hOverlay = imshow( ...
            results.boundingBoxImage,...
            'Parent',UI.axOverlay,...
            'InitialMagnification','fit');

        hOverlay.ButtonDownFcn = @(~,~) ...
            openImageWindow( ...
            results.boundingBoxImage,...
            'Bounding Box View');

    case 'Segmentation'

        hOverlay = imshow( ...
            results.crackMap,...
            'Parent',UI.axOverlay,...
            'InitialMagnification','fit');

        hOverlay.ButtonDownFcn = @(~,~) ...
            openImageWindow( ...
            results.crackMap,...
            'Segmentation View');

    end

    axis(UI.axOverlay,'image');
    axis(UI.axOverlay,'off');

    UI.axOverlay.XColor = 'none';
    UI.axOverlay.YColor = 'none';
end

%% ============================================================
% CLEAR SESSION
%% ============================================================

function clearSession()

    cla(UI.axOriginal);
    cla(UI.axEnhanced);
    cla(UI.axOverlay);
    cla(UI.axSegmentation);

    UI.qualityLabel.Text = '0%';
    UI.confidenceLabel.Text = '0%';
    UI.crackLabel.Text = '0';

    UI.severityLabel.Text = ...
        'WAITING';

    UI.statusLabel.Text = ...
        'READY';

    UI.resultsTable.Data = {};

    UI.recommendationText.Value = ...
        {
        '================================================'
        ' AI WELD ASSESSMENT REPORT'
        '================================================'
        ''
        'System Status: READY'
        ''
        'Awaiting image upload and analysis.'
        };

    UI.recommendationText.BackgroundColor = ...
        [0.98 0.98 0.99];

    UI.severityLabel.FontColor = ...
        [0 0 0];

    UI.statusLabel.FontColor = ...
        [0 0 0];

    app = getappdata(fig,'APP');

        app.originalImage = [];
        app.roiImage = [];
        app.analysisResults = [];

        app.currentFile = "";
        app.isImageLoaded = false;
        app.isAnalyzed = false;

    setappdata(fig,'APP',app);

    UI.analyzeBtn.Enable = 'off';

end

%% ============================================================
% EXPORT PDF REPORT
%% ============================================================

function exportPDF()

    app = getappdata(fig,'APP');

    if isempty(app.analysisResults)

        uialert(fig,...
            'Run analysis first.',...
            'No Results');

        return;

    end

    results = app.analysisResults;

    [file,path] = uiputfile( ...
        '*.pdf',...
        'Save PDF Report');

    if isequal(file,0)
        return;
    end

    pdfFile = fullfile(path,file);

    import mlreportgen.report.*
    import mlreportgen.dom.*

    rpt = Report(pdfFile,'pdf');

    tp = TitlePage;

    tp.Title = ...
        'Ultrasonic Weld Inspection Report';

    tp.Author = 'ULTRASONIC_WELDING_ANALYZER_V3';

    add(rpt,tp);

    add(rpt,TableOfContents);

    ch = Chapter('Title',...
        'Inspection Summary');

    append(ch,...
        Paragraph( ...
        ['Quality Score: ',...
        num2str(results.qualityScore)]));

    append(ch,...
        Paragraph( ...
        ['Confidence: ',...
        num2str(results.confidence)]));

    append(ch,...
        Paragraph( ...
        ['Status: ',...
        results.status]));

    append(ch,...
        Paragraph( ...
        ['Severity: ',...
        results.severity]));

    add(rpt,ch);

    close(rpt);

    uialert(fig,...
        'PDF exported successfully.',...
        'Export Complete');

end
%% ============================================================
% EXPORT EXCEL REPORT
%% ============================================================

function exportExcel()

    app = getappdata(fig,'APP');

    if isempty(app.analysisResults)

        uialert(fig,...
            'Run analysis first.',...
            'No Results');

        return;

    end

    results = app.analysisResults;

    [file,path] = uiputfile( ...
        '*.xlsx',...
        'Save Excel Report');

    if isequal(file,0)
        return;
    end

    excelFile = fullfile(path,file);

    metrics = table( ...
    results.qualityScore,...
    results.confidence,...
    results.crackCount,...
    string(results.severity),...
    string(results.status),...
    string(results.defectType),...
    'VariableNames',...
    {'QualityScore',...
     'Confidence',...
     'CrackCount',...
     'Severity',...
     'Status',...
     'DefectType'});

writetable( ...
    metrics,...
    excelFile,...
    'Sheet','Summary');

    uialert(fig,...
        'Excel report exported.',...
        'Export Complete');

end

%% ============================================================
% EXPORT HTML REPORT
%% ============================================================

function exportHTML()

    app = getappdata(fig,'APP');

    if isempty(app.analysisResults)

        uialert(fig,...
            'Run analysis first.',...
            'No Results');

        return;

    end

    results = app.analysisResults;

    [file,path] = uiputfile( ...
        '*.html',...
        'Save HTML Report');

    if isequal(file,0)
        return;
    end

    htmlFile = fullfile(path,file);

    fid = fopen(htmlFile,'w');

    fprintf(fid,...
        '<html><head><title>Weld Report</title></head><body>');

    fprintf(fid,...
        '<h1>Ultrasonic Weld Inspection Report</h1>');

    fprintf(fid,...
        '<p><b>Quality Score:</b> %.2f</p>',...
        results.qualityScore);

    fprintf(fid,...
        '<p><b>Confidence:</b> %.2f</p>',...
        results.confidence);

    fprintf(fid,...
        '<p><b>Status:</b> %s</p>',...
        results.status);

    fprintf(fid,...
        '<p><b>Severity:</b> %s</p>',...
        results.severity);

    fprintf(fid,...
        '<p><b>Defect Type:</b> %s</p>',...
        results.defectType);

    fprintf(fid,...
        '</body></html>');

    fclose(fid);

    uialert(fig,...
        'HTML report exported.',...
        'Export Complete');

end

%% ============================================================
% MATERIAL OPTIMIZATION SCORE
%% ============================================================

function [score,...
          optTime,...
          optPressure,...
          optAmplitude,...
          optFrequency] = ...
    calculateMaterialScore( ...
    material,...
    thickness,...
    weldTime,...
    pressure,...
    amplitude)

    [optTime,...
     optPressure,...
     optAmplitude,...
     optFrequency] = ...
        getRecommendedParameters( ...
        material,...
        thickness);

    deviation = ...
        abs(weldTime-optTime)/optTime + ...
        abs(pressure-optPressure)/optPressure + ...
        abs(amplitude-optAmplitude)/optAmplitude;

    score = max(0,100 - deviation*35);

end

%% ============================================================
% LOAD EXAMPLE IMAGE
%% ============================================================

function loadExampleImage(exampleType)

    switch exampleType

        case 'Crack-Free'
            img = generateSyntheticWeldImage('crack-free');

        case 'Non-Extrusion Crack'
            img = generateSyntheticWeldImage('non-extrusion');

        case 'Material Extrusion Crack'
            img = generateSyntheticWeldImage('extrusion');

        otherwise
            return;

    end

    app = getappdata(fig,'APP');

    app.originalImage = img;

    setappdata(fig,'APP',app);

    imshow(img,...
        'Parent',UI.axOriginal,...
        'InitialMagnification','fit');

    axis(UI.axOriginal,'image');
    axis(UI.axOriginal,'off');

    UI.analyzeBtn.Enable = 'on';

end


%% ============================================================
% SYNTHETIC EXAMPLE GENERATOR
%% ============================================================

% Helper function to generate synthetic weld images for demonstration
function img = generateSyntheticWeldImage(type)
    imgSize = 512;
    
    img = 180 + 30 * randn(imgSize, imgSize);
    img = img - 30;
    
    rectWidth = 230;
    rectHeight = 150;
    rectCenter = [imgSize/2, imgSize/2];
    rectX = round(rectCenter(1) - rectWidth/2);
    rectY = round(rectCenter(2) - rectHeight/2);
    
    img(rectY:rectY+rectHeight, rectX:rectX+rectWidth) = ...
        img(rectY:rectY+rectHeight, rectX:rectX+rectWidth) - 50;
    
    teethSpacing = 15;
    for y = rectY+20:teethSpacing:rectY+rectHeight-20
        img(y:y+2, rectX+10:rectX+rectWidth-10) = ...
            img(y:y+2, rectX+10:rectX+rectWidth-10) - 30;
    end
    
    switch type
        case 'crack-free'
            img = img + 5 * randn(imgSize, imgSize);
            
        case 'non-extrusion'
            for i = 1:4
                startX = rectX + 50 + rand*100;
                startY = rectY + 30 + rand*120;
                
                for step = 1:50
                    x = round(startX + step * (0.5 + rand*0.5));
                    y = round(startY + step * (0.3 + rand*0.7));
                    if x > rectX && x < rectX+rectWidth && y > rectY && y < rectY+rectHeight
                        img(y, x) = img(y, x) - 80;
                        if step > 1
                            img(y-1:y+1, x-1:x+1) = img(y-1:y+1, x-1:x+1) - 60;
                        end
                    end
                end
            end
            
        case 'extrusion'
            for i = 1:3
                startX = rectX + 80 + rand*80;
                startY = rectY + 60 + rand*40;
                
                for step = 1:80
                    x = round(startX + step * (1 + rand*1));
                    y = round(startY + step * (0.5 + rand*0.8));
                    if x > rectX && x < rectX+rectWidth && y > rectY && y < rectY+rectHeight
                        img(y-2:y+2, x-2:x+2) = img(y-2:y+2, x-2:x+2) - 100;
                        if step > 20 && step < 60
                            img(y-3, x-3:x+3) = img(y-3, x-3:x+3) + 50;
                        end
                    end
                end
            end
    end
    
    img = img + 10 * randn(imgSize, imgSize);
    img = mat2gray(img);
    img = im2uint8(img);
    img = cat(3, img, img, img);
end

%% ============================================================
% IMAGE VIEWER
%% ============================================================

function openImageWindow(img,titleText)

    viewerFig = figure( ...
        'Name',titleText,...
        'NumberTitle','off',...
        'Color','white',...
        'Units','normalized',...
        'Position',[0.1 0.1 0.8 0.8]);

    ax = axes(viewerFig);

    imshow(img,...
        'Parent',ax,...
        'InitialMagnification','fit');

    title(titleText);

    zoom(viewerFig,'on');
    pan(viewerFig,'on');

    axtoolbar(ax,...
        {'zoomin','zoomout','pan','restoreview'});
   end
end