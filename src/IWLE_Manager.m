%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% File Name   : IWLE_Manager.m
% Project     : Ultrasonic Weld Quality Analytics Platform
% Description :
% Implements the Intelligent Weld Learning Engine (IWLE) management
% interface for database administration, model training, dataset
% management, statistics visualization, performance evaluation,
% and machine learning workflow control.
%
% Author      : Sagar Sant
% Institute   : Indian Institute of Technology Guwahati
% Year        : 2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function IWLE_Manager()

fig = uifigure;

fig.Name = 'Intelligent Weld Learning Engine';

fig.Position = [200 100 1200 700];

%% ============================================================
% GRID
%% ============================================================

grid = uigridlayout(fig);

grid.RowHeight = {60,'1x'};

grid.ColumnWidth = {'1x','2x'};

%% ============================================================
% TITLE
%% ============================================================

titleLabel = uilabel(grid);

titleLabel.Text = "INTELLIGENT WELD LEARNING ENGINE";

titleLabel.FontSize = 26;

titleLabel.FontWeight = 'bold';

titleLabel.HorizontalAlignment = 'center';

titleLabel.Layout.Row = 1;

titleLabel.Layout.Column = [1 2];

%% ============================================================
% LEFT PANEL
%% ============================================================

left = uipanel(grid);

left.Title = 'AI CONTROL CENTER';

left.Layout.Row = 2;

left.Layout.Column = 1;

leftGrid = uigridlayout(left);

leftGrid.RowHeight = {45 45 45 45 45 45 45 45,'1x'};

%% Buttons

learnBtn = uibutton(leftGrid,...
    'Text','Learn Current Weld');

trainBtn = uibutton(leftGrid,...
    'Text','Train AI Model');

testBtn = uibutton(leftGrid,...
    'Text','Test AI');

openBtn = uibutton(leftGrid,...
    'Text','Open Database');

exportBtn = uibutton(leftGrid,...
    'Text','Export Dataset');

importBtn = uibutton(leftGrid,...
    'Text','Import Dataset');

statsBtn = uibutton(leftGrid,...
    'Text','View Statistics');

performanceBtn = uibutton(leftGrid,...
    'Text','Model Performance');

%% ============================================================
% RIGHT PANEL
%% ============================================================

right = uipanel(grid);

right.Title = 'AI INFORMATION';

right.Layout.Row = 2;

right.Layout.Column = 2;

rightGrid = uigridlayout(right);

rightGrid.RowHeight = {180,'1x'};

summary = uitextarea(rightGrid);

summary.Editable = 'off';

summary.FontName = 'Consolas';

summary.Value = {
'Intelligent Weld Learning Engine'
' '
'Database Images : 0'
'Good            : 0'
'Acceptable      : 0'
'Defective       : 0'
' '
'Random Forest : Not Trained'
'Accuracy      : --'
'Version       : 2.0'
};

log = uitextarea(rightGrid);

log.Editable = 'off';

log.FontName = 'Consolas';

log.Value = {
'AI Log'
'-----------------------------'
'System Ready.'
};

refreshInformation();

learnBtn.ButtonPushedFcn = @(~,~)learnCurrentWeld();
trainBtn.ButtonPushedFcn = @(~,~)trainAI();
testBtn.ButtonPushedFcn  = @(~,~)testAI();
openBtn.ButtonPushedFcn = @(~,~)openDatabase();
statsBtn.ButtonPushedFcn = @(~,~)viewStatistics();
exportBtn.ButtonPushedFcn = ...
    @(~,~)exportDataset();

importBtn.ButtonPushedFcn = ...
    @(~,~)importDataset();

performanceBtn.ButtonPushedFcn = ...
    @(~,~)modelPerformance();

function learnCurrentWeld()

    roi = getappdata(0,'IWLE_LastROI');
    metadata = getappdata(0,'IWLE_LastMetadata');

    if isempty(roi)
        uialert(fig,'Analyze a weld first.','No Weld');
        return;
    end

    results = IWLE_Core(roi,metadata,"learn");

    refreshInformation();

    timeStamp = char(string(datetime("now"),"HH:mm:ss"));

    log.Value = [log.Value;
                {sprintf('[%s] Learned Record %d', ...
                timeStamp, ...
                results.Record.ID)}];

     uialert(fig,results.Message,'IWLE');

end

function trainAI()

    results = IWLE_Core([],[],"train");

    refreshInformation();

    log.Value = [log.Value;
            {sprintf('[%s] AI Model Trained', ...
            char(string(datetime("now"),"HH:mm:ss")))}];

    uialert(fig,results.Message,'Training');

end

function testAI()

    roi = getappdata(0,'IWLE_LastROI');
    metadata = getappdata(0,'IWLE_LastMetadata');

    if isempty(roi)
        uialert(fig,'Analyze a weld first.','No Weld');
        return;
    end

    results = IWLE_Core(roi,metadata,"inspect");

    refreshInformation();

    timeStamp = char(string(datetime("now"),"HH:mm:ss"));

    log.Value = [log.Value;
            {sprintf('[%s] Inspection Complete', ...
            timeStamp)}];


    disp(results);

end

%% ============================================================
% OPEN DATABASE
%% ============================================================

function openDatabase()

filename = "IWLE_Database.mat";

if ~exist(filename,"file")

    uialert(fig,...
        "Database not found.",...
        "IWLE");

    return;

end

S = load(filename);

database = S.database;

createDatabaseViewer(database);

end

%% ============================================================
% DATABASE VIEWER
%% ============================================================

function createDatabaseViewer(database)

dbFig = uifigure( ...
    'Name','IWLE Database',...
    'Position',[200 150 900 500]);

tbl = uitable(dbFig);

tbl.FontSize = 12;

tbl.RowStriping = "on";

tbl.Position = [20 20 860 460];

rows = cell(database.TotalImages,6);

for k = 1:database.TotalImages

    r = database.Records(k);

    rows{k,1} = uint32(r.ID);
    rows{k,2} = char(string(r.TimeStamp));

    switch upper(string(r.Label))

    case "GOOD"
        rows{k,3} = char("GOOD");

    case "ACCEPTABLE"
        rows{k,3} = char("ACCEPTABLE");

    case "DEFECTIVE"
        rows{k,3} = char("DEFECTIVE");

    otherwise
        rows{k,3} = char(string(r.Label));

    end

    switch upper(string(r.Prediction))

    case "GOOD"
        rows{k,4} = char("GOOD");

    case "ACCEPTABLE"
        rows{k,4} = char("ACCEPTABLE");

    case "DEFECTIVE"
        rows{k,4} = char("DEFECTIVE");

    otherwise
        rows{k,4} = char(string(r.Prediction));

    end
    %% Confidence

    if isempty(r.Confidence)

       rows{k,5} = '-';

    else

        rows{k,5} = sprintf('%.1f%%',100*double(r.Confidence));

    end

    %% Status
    
        status = char(string(r.Status));

        if contains(status,"AUTO","IgnoreCase",true)
            status = 'AUTO';
        end

            rows{k,6} = status;
end

tbl.Data = rows;

tbl.CellSelectionCallback = ...
    @(src,event)viewRecord(event);


tbl.ColumnName = { ...
    'ID',...
    'Time',...
    'Label',...
    'Prediction',...
    'Confidence',...
    'Status'};

tbl.ColumnWidth = {
    60,...
    170,...
    140,...
    140,...
    90,...
    90};

%% ============================================================
% VIEW RECORD
%% ============================================================

function viewRecord(event)

if isempty(event.Indices)
    return;
end

row = event.Indices(1);

S = load("IWLE_Database.mat");

database = S.database;

record = database.Records(row);

showRecord(record);

end

%% ============================================================
% SHOW RECORD
%% ============================================================

function showRecord(record)

fig = uifigure( ...
    'Name',sprintf("Record %d",record.ID),...
    'Position',[250 150 900 600]);

grid = uigridlayout(fig);

grid.RowHeight = {250,'1x'};

grid.ColumnWidth = {'1x','1x'};

%% ORIGINAL IMAGE

ax1 = uiaxes(grid);

imshow(record.OriginalROI,...
    'Parent',ax1);

title(ax1,'Original ROI');

%% STANDARD IMAGE

ax2 = uiaxes(grid);

imshow(record.StandardROI,...
    'Parent',ax2);

title(ax2,'Standard ROI');

%% INFORMATION

txt = uitextarea(grid);

txt.Layout.Row = 2;
txt.Layout.Column = [1 2];

txt.Editable = 'off';

txt.FontName = 'Consolas';

txt.Value = {

sprintf('ID              : %d',record.ID)

sprintf('Time            : %s',string(record.TimeStamp))

sprintf('Material        : %s',record.Metadata.Material)

sprintf('Thickness       : %s mm',string(record.Metadata.Thickness))

sprintf('Prediction      : %s',string(record.Prediction))

sprintf('Status          : %s',string(record.Status))

sprintf('Confidence      : %.2f',double(record.Confidence))

sprintf('Feature Count   : %d',record.FeatureCount)

};

end

end

%% ============================================================
% VIEW DATASET STATISTICS
%
% Displays database statistics and dataset information.
%% ============================================================

function viewStatistics()

filename = "IWLE_Database.mat";

if ~exist(filename,"file")

    uialert(fig,...
        "Database not found.",...
        "IWLE");

    return;

end

S = load(filename);

db = S.database;

%% ------------------------------------------------------------
% Count Labels
%% ------------------------------------------------------------

good = 0;
acceptable = 0;
defective = 0;

%% ------------------------------------------------------------
% Preallocate Statistics Arrays
%% ------------------------------------------------------------

confidence = NaN(db.TotalImages,1);

quality = NaN(db.TotalImages,1);

materials = strings(db.TotalImages,1);

thickness = NaN(db.TotalImages,1);

for i = 1:db.TotalImages

    r = db.Records(i);

    switch upper(string(r.Label))

        case "GOOD"
            good = good + 1;

        case "ACCEPTABLE"
            acceptable = acceptable + 1;

        case "DEFECTIVE"
            defective = defective + 1;

    end

    if isfield(r,'Confidence') && ~isempty(r.Confidence)
    confidence(i) = double(r.Confidence);
    end

    if isfield(r,'QualityScore') && ~isempty(r.QualityScore)
    quality(i) = double(r.QualityScore);
    end

    if isfield(r,'Metadata')

        if isfield(r.Metadata,'Material')
            materials(i) = string(r.Metadata.Material);
        end

        if isfield(r.Metadata,'Thickness')
            thickness(i) = double(r.Metadata.Thickness);
        end

    end

end

%% ------------------------------------------------------------
% Statistics
%% ------------------------------------------------------------

if isempty(confidence)

    avgConfidence = NaN;

else

    avgConfidence = mean(confidence,'omitnan');

end

if isempty(quality)

    avgQuality = NaN;

else

    avgQuality = mean(quality,'omitnan');

end

%% ------------------------------------------------------------
% DISPLAY WINDOW
%% ------------------------------------------------------------

statsFig = uifigure(...
    'Name','IWLE Dataset Statistics',...
    'Position',[250 150 900 600]);

grid = uigridlayout(statsFig);

grid.ColumnWidth = {300,'1x'};

%% ------------------------------------------------------------
% PIE CHART
%% ------------------------------------------------------------

ax = uiaxes(grid);

pie(ax,[good acceptable defective]);

title(ax,'Class Distribution');

legend(ax,...
    {'GOOD','ACCEPTABLE','DEFECTIVE'},...
    'Location','southoutside');

%% ------------------------------------------------------------
% INFORMATION PANEL
%% ------------------------------------------------------------

txt = uitextarea(grid);

txt.Editable = 'off';

txt.FontName = 'Consolas';

txt.FontSize = 13;

txt.Value = {

'======================================================='

'              IWLE DATASET STATISTICS'

'======================================================='

' '

sprintf('Total Images          : %d',db.TotalImages)

sprintf('GOOD                  : %d',good)

sprintf('ACCEPTABLE            : %d',acceptable)

sprintf('DEFECTIVE             : %d',defective)

' '

sprintf('Average Confidence    : %.2f %%',100*avgConfidence)

sprintf('Average Quality Score : %.2f',avgQuality)

' '

sprintf('Feature Dimension     : %d',db.FeatureLength)

sprintf('Dataset Version       : %s',string(db.Version))

sprintf('Total Learned         : %d',db.TotalLearned)

sprintf('Total Inspections     : %d',db.TotalInspections)

sprintf('Total Updates         : %d',db.TotalUpdates)

' '

sprintf('Latest Update         : %s',string(db.LastUpdated))

' '

sprintf('Feature Version       : %d',db.FeatureLength)

sprintf('Database Status       : READY')

};

end

%% ============================================================
% EXPORT DATASET
%
% Exports the complete IWLE database to another MAT file.
%% ============================================================

function exportDataset()

if ~exist("IWLE_Database.mat","file")

    uialert(fig,...
        "No database available.",...
        "Export");

    return;

end

[file,path] = uiputfile( ...
    '*.mat',...
    'Export IWLE Dataset',...
    'IWLE_Dataset_Backup.mat');

if isequal(file,0)
    return;
end

copyfile( ...
    "IWLE_Database.mat",...
    fullfile(path,file));

log.Value = [log.Value;
    {"Dataset exported successfully."}];

uialert(fig,...
    "Dataset exported successfully.",...
    "IWLE");

end

%% ============================================================
% IMPORT DATASET
%
% Imports an existing IWLE dataset.
%% ============================================================

function importDataset()

[file,path] = uigetfile( ...
    '*.mat',...
    'Select IWLE Dataset');

if isequal(file,0)
    return;
end

copyfile( ...
    fullfile(path,file),...
    "IWLE_Database.mat");

refreshInformation();

log.Value = [log.Value;
    {"Dataset imported successfully."}];

uialert(fig,...
    "Dataset imported successfully.",...
    "IWLE");

end

%% ============================================================
% MODEL PERFORMANCE
%% ============================================================

function modelPerformance()

fig2 = uifigure(...
    'Name','IWLE Model Performance',...
    'Position',[250 150 700 500]);

txt = uitextarea(fig2);

txt.Position = [20 20 660 460];

txt.FontName = 'Consolas';

txt.Editable = 'off';

modelStatus = "NOT TRAINED";
accuracy = "--";

if exist("IWLE_Model.mat","file")

    M = load("IWLE_Model.mat");

    modelStatus = "TRAINED";

    if isfield(M,"model")

        if isfield(M.model,"Accuracy")

            accuracy = sprintf("%.2f %%",...
                M.model.Accuracy);

        end

    end

end

txt.Value = {

'==============================================='
'          IWLE MODEL PERFORMANCE'
'==============================================='
''

sprintf('Model Status       : %s',modelStatus)

sprintf('Accuracy           : %s',accuracy)

''

'Algorithms'

' • Random Forest'

' • Isolation Forest'

' • One-Class SVM'

' • CNN (Future)'

''

'Database'

};

if exist("IWLE_Database.mat","file")

    S = load("IWLE_Database.mat");

    db = S.database;

    txt.Value(end+1) = ...
        {sprintf('Images             : %d',db.TotalImages)};

    txt.Value(end+1) = ...
        {sprintf('Feature Dimension  : %d',db.FeatureLength)};

end

end

%% ============================================================
% REFRESH AI INFORMATION PANEL
%
% Updates the AI Information panel by reading the latest
% database and trained model information.
%
% Displays:
%   • Database statistics
%   • Class distribution
%   • Model status
%   • Training accuracy
%   • IWLE version
%% ============================================================

function refreshInformation()

if exist("IWLE_Database.mat","file")

    S = load("IWLE_Database.mat");
    db = S.database;

else

    return

end

good = 0;
acceptable = 0;
defective = 0;

for i = 1:db.TotalImages

    switch upper(string(db.Records(i).Label))

        case "GOOD"
            good = good + 1;

        case "ACCEPTABLE"
            acceptable = acceptable + 1;

        case "DEFECTIVE"
            defective = defective + 1;

    end

end

modelText = "Not Trained";

accuracy = "--";

if exist("IWLE_Model.mat","file")

    modelText = "Trained";

    M = load("IWLE_Model.mat");

    if isfield(M,"model")

        if isfield(M.model,"Accuracy")

            accuracy = sprintf("%.2f %%",M.model.Accuracy);

        end

    end

end

summary.Value = {

'Intelligent Weld Learning Engine'
' '

sprintf('Database Images : %d',db.TotalImages)

sprintf('Good            : %d',good)

sprintf('Acceptable      : %d',acceptable)

sprintf('Defective       : %d',defective)

' '

sprintf('Random Forest : %s',modelText)

sprintf('Accuracy      : %s',accuracy)

sprintf('Version       : %s',db.Version)

};

end

end