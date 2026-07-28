
function results = IWLE_Core(roiImage,metadata,mode)
%% ============================================================
% INTELLIGENT WELD LEARNING ENGINE (IWLE)
%
% File        : IWLE_Core.m
% Version     : 2.0
% Phase       : 1A
%
% Description:
% Core controller for the Intelligent Weld Learning Engine.
%
% Modes:
%   learn
%   inspect
%   update
%   database
%
%% ============================================================

VERSION = "2.0";

if nargin < 3
    error('IWLE:InvalidInput',...
        'Usage: results = IWLE_Core(roiImage,metadata,mode)');
end

mode = lower(string(mode));

if ismember(mode,["learn","inspect","update"])

    if isempty(roiImage)

        error( ...
            "IWLE:EmptyImage", ...
            "ROI image cannot be empty.");

    end

end

if nargin < 2 || isempty(metadata)
    metadata = struct();
end

mode = lower(string(mode));

results = initializeResults(VERSION,mode);

database = loadDatabase();

startupSelfTest();

switch mode

    case "learn"

    %% --------------------------------------------------------
    % Analysis Results (if available)
    %% --------------------------------------------------------

    if isfield(metadata,"Analysis")

        analysis = metadata.Analysis;

    else

        analysis = struct();

    end

    results = learnMode( ...
        roiImage,...
        metadata,...
        analysis,...
        database,...
        results);

    case "inspect"
        results = inspectMode(roiImage,metadata,database,results);

    case "update"
        results = updateMode(roiImage,metadata,database,results);

    case "database"
        results = databaseMode(database,results);

    case "train"

    results = trainMode(database,results);

    otherwise
        error('IWLE:UnknownMode','Unknown operating mode.');

end

end

%% ============================================================
function results = initializeResults(version,mode)

results = struct();

results.Version      = version;
results.Mode         = mode;
results.Success      = false;
results.Message      = "";
results.TimeStamp    = datetime('now');

results.Database     = [];
results.Record       = [];
results.Features     = [];
results.Statistics   = [];

end

%% ============================================================
function database = initializeDatabase()

database = struct();

database.Version = "2.0";
database.Created = datetime('now');
database.LastUpdated = datetime('now');

database.TotalImages = 0;
database.TotalLearned = 0;
database.TotalInspections = 0;
database.TotalUpdates = 0;

database.FeatureLength = 0;
database.FeatureVersion = "1.1";

database.FeatureNames = {

'Mean Intensity'
'Median Intensity'
'Intensity Std'
'Intensity Variance'
'Minimum Intensity'
'Maximum Intensity'
'Intensity Range'
'Entropy'
'Skewness'
'Kurtosis'

'Histogram Peak'
'Histogram Mean'
'Histogram Std'
'Histogram Entropy'

'Gradient Mean'
'Gradient Std'
'Gradient Maximum'
'Gradient Median'

'Edge Count'
'Edge Density'
'Connected Edges'

'Local Entropy Mean'
'Local Entropy Std'

'Local Std Mean'
'Local Std Std'

'Image Height'
'Image Width'
'Aspect Ratio'

'GLCM Contrast'
'GLCM Correlation'
'GLCM Energy'
'GLCM Homogeneity'

'FFT Mean'
'FFT Std'
'FFT Maximum'
'FFT Median'

'Shape Area'
'Shape Perimeter'
'Shape Eccentricity'
'Shape Solidity'
'Shape Extent'

'Gradient Direction Mean'
'Gradient Direction Std'
'Gradient Direction Median'

};

database.Records = struct([]);

database.Settings = struct();
database.Settings.Normalize = true;
database.Settings.AutoSave = true;
database.Settings.MaxRecords = inf;

database.Statistics = struct();

%% ============================================================
% DATASET
%% ============================================================

database.Dataset = struct();

database.Dataset.Version = "1.0";

database.Dataset.Created = datetime('now');

database.Dataset.LastUpdated = datetime('now');

database.Dataset.TotalSamples = 0;

database.Dataset.LabelledSamples = 0;

database.Dataset.UnlabelledSamples = 0;

database.Dataset.Classes = ...
    ["GOOD","ACCEPTABLE","DEFECTIVE","UNKNOWN"];

end

%% ============================================================

function database = loadDatabase()

filename = "IWLE_Database.mat";

if exist(filename,"file")

    S = load(filename);

    if isfield(S,"database")

    database = S.database;

    else

    error("IWLE:DatabaseCorrupted", ...
          "IWLE_Database.mat is invalid. Restore from backup.");

    end

else

    database = initializeDatabase();

end

%% ============================================================
% DATABASE COMPATIBILITY UPGRADE
%% ============================================================

if ~isfield(database,'FeatureVersion')
    database.FeatureVersion = "1.1";
end

if ~isfield(database,'FeatureLength')
    database.FeatureLength = 0;
end

for k = 1:length(database.Records)

    if ~isfield(database.Records(k),'Label')
        database.Records(k).Label = "UNKNOWN";
    end

    if ~isfield(database.Records(k),'Verified')
        database.Records(k).Verified = false;
    end

    if ~isfield(database.Records(k),'Operator')
        database.Records(k).Operator = "";
    end

    if ~isfield(database.Records(k),'Remarks')
        database.Records(k).Remarks = "";
    end

    if ~isfield(database.Records(k),'LabelTime')
        database.Records(k).LabelTime = NaT;
    end

    %----------------------------------------------------------
    % Fracture compatibility
    %----------------------------------------------------------

    if ~isfield(database.Records(k),'FractureDetected')
        database.Records(k).FractureDetected = false;
    end

    if ~isfield(database.Records(k),'FractureArea')
        database.Records(k).FractureArea = 0;
    end

    if ~isfield(database.Records(k),'FractureLength')
        database.Records(k).FractureLength = 0;
    end

    if ~isfield(database.Records(k),'FractureCount')
        database.Records(k).FractureCount = 0;
    end

end

%% ============================================================
% Update Dataset Statistics
%% ============================================================

database.Dataset.TotalSamples = ...
    database.TotalImages;

labels = strings(database.TotalImages,1);

for k = 1:database.TotalImages

    labels(k) = database.Records(k).Label;

end

database.Dataset.LabelledSamples = ...
    sum(labels ~= "UNKNOWN");

database.Dataset.UnlabelledSamples = ...
    sum(labels == "UNKNOWN");

database.Dataset.LastUpdated = ...
    datetime('now');

database = refreshDatasetStatistics(database);
saveDatabase(database);

end

%% ============================================================
function saveDatabase(database)

database.LastUpdated = datetime('now');

mainFile   = "IWLE_Database.mat";
backupFile = "IWLE_Database_Backup.mat";
tempFile   = "IWLE_Database_tmp.mat";

% Backup current database
if exist(mainFile,"file")
    copyfile(mainFile, backupFile);
end

% Save to a temporary file first
save(tempFile,"database","-v7.3");

% Only replace the database if the temporary file exists
if exist(tempFile,"file")
    movefile(tempFile, mainFile, "f");
else
    error("Failed to save temporary database file.");
end

end
%% ============================================================
% LEARN MODE
%% ============================================================

function results = learnMode( ...
    roiImage,...
    metadata,...
    analysis,...
    database,...
    results)

%% ------------------------------------------------------------
% Standardize ROI
%% ------------------------------------------------------------

standardROI = ...
    standardizeImage( ...
    roiImage);

%% ------------------------------------------------------------
% Generate Feature Images
%% ------------------------------------------------------------

featureImages = ...
    generateFeatureImages( ...
    standardROI);

%% ------------------------------------------------------------
% Extract AI Features
%% ------------------------------------------------------------

imageFeatures = ...
    extractFeatures( ...
    standardROI,...
    featureImages);

mlFeatures = ...
    getMLFeatures( ...
    roiImage,...
    metadata);

features = ...
    [imageFeatures(:); mlFeatures(:)]';

%% ------------------------------------------------------------
% Create Record
%% ------------------------------------------------------------

% Verify database consistency
if database.TotalImages ~= numel(database.Records)
    error('IWLE:DatabaseCorrupted', ...
        'Database inconsistency detected. TotalImages (%d) does not match number of records (%d). Restore from backup.', ...
        database.TotalImages, numel(database.Records));
end

record = struct();

% Always use the next available ID
if isempty(database.Records)

    nextID = 1;

else

    ids = [database.Records.ID];

    nextID = max(ids) + 1;

    % Safety check
    if any(ids == nextID)
        error('IWLE:DuplicateID', ...
            'Duplicate record ID detected.');
    end

end

record.ID = nextID;

record.TimeStamp = datetime('now');

record.Metadata = metadata;
%% ------------------------------------------------------------
% Analysis Results
%% ------------------------------------------------------------

record.Analysis = analysis;

record.ImageSize = ...
    size(roiImage);

%% ------------------------------------------------------------
% Machine Learning Fields
%% ------------------------------------------------------------

record.Verified = false;

record.Operator = "";

record.Remarks = "";

record.LabelTime = NaT;

%% ------------------------------------------------------------
% Classification
%% ------------------------------------------------------------

record.Prediction = "UNKNOWN";

record.Status = "UNCLASSIFIED";

record.Confidence = 0;

record.AnomalyScore = 0;

%% ------------------------------------------------------------
% Feature Storage
%% ------------------------------------------------------------

record.Features = [];

record.Explanation = [];

%% ------------------------------------------------------------
% Store Images
%% ------------------------------------------------------------

record.OriginalROI = ...
    roiImage;

record.StandardROI = ...
    standardROI;

%% ------------------------------------------------------------
% Analysis Images
%% ------------------------------------------------------------

if isfield(analysis,"originalImage")

    record.Images.Original = analysis.originalImage;

end

if isfield(analysis,"enhancedImage")

    record.Images.Enhanced = analysis.enhancedImage;

end

if isfield(analysis,"crackMask")

    record.Images.CrackMask = analysis.crackMask;

end

if isfield(analysis,"overlayImage")

    record.Images.Overlay = analysis.overlayImage;

end

%% Development Mode
record.FeatureImages = [];

%% ------------------------------------------------------------
% Placeholder for Future AI Features
%% ------------------------------------------------------------

record.Features = features;

record.FeatureCount = ...
    length(features);

record.FeatureVersion = ...
    "1.1";

record.NormalityScore = [];

record.SimilarityScore = [];

record.AnomalyScore = [];

record.Prediction = "";

record.Confidence = [];

record.RandomForestConfidence = [];

record.AnomalyLabel = "";

%% ------------------------------------------------------------
% Dataset Information
%% ------------------------------------------------------------

if isfield(metadata,'Analysis')

    analysis = metadata.Analysis;

    %% Automatic label from analyzer

    score = analysis.qualityScore;

    if score >= 85

        record.Label = "GOOD";

    elseif score >= 70

        record.Label = "ACCEPTABLE";

    else

        record.Label = "DEFECTIVE";

    end

    %% Initial prediction

    record.Prediction = record.Label;

    %% Confidence

    record.Confidence = analysis.confidence;

    %% Status

    record.Status = "AUTO LABELLED (ANALYZER)";

else

    record.Label = "UNKNOWN";
    record.Prediction = "UNKNOWN";
    record.Confidence = 0;
    record.Status = "UNLABELLED";

end

record.Remarks = "";

record.Operator = "";

record.Verified = false;

record.LabelTime = NaT;

record.DatasetVersion = "1.0";

record.DatasetID = record.ID;

%% ------------------------------------------------------------
% Store Analysis Summary
%% ------------------------------------------------------------

if isfield(metadata,'Analysis')

    analysis = metadata.Analysis;

    record.QualityScore = analysis.qualityScore;

    record.Severity = analysis.severity;

    record.DefectType = analysis.defectType;

    record.CrackCount = analysis.crackCount;

    % Fracture information
    record.FractureDetected = analysis.fractureDetected;

    record.FractureArea = analysis.fractureArea;

    record.FractureLength = analysis.fractureLength;

    record.FractureCount = analysis.fractureCount;

end

%% ============================================================
% Update Feature Matrix
%% ============================================================

if ~isfield(database,'FeatureMatrix') || isempty(database.FeatureMatrix)

    database.FeatureMatrix = record.Features;

else

    database.FeatureMatrix = ...
        [database.FeatureMatrix;
         record.Features];

end
%% ============================================================
% Database Statistics
%% ============================================================

database.FeatureMean = ...
    mean(database.FeatureMatrix,1);

if size(database.FeatureMatrix,1) > 1

    database.FeatureStd = ...
        std(database.FeatureMatrix,0,1);

else

    database.FeatureStd = ...
        ones(1,length(record.Features));

end

database.FeatureStd( ...
    database.FeatureStd==0) = 1;

database.Statistics.DatabaseSize = ...
    size(database.FeatureMatrix,1);

database.Statistics.FeatureCount = ...
    size(database.FeatureMatrix,2);

database.Statistics.LastLearned = ...
    datetime('now');

%% ============================================================
% Update Adaptive AI Model
%% ============================================================

database = updateAnomalyModel(database);

%% ============================================================
% AI Statistics
%% ============================================================

database.AIStatistics.TotalComparisons = ...
    database.TotalImages;

database.AIStatistics.TotalLearned = ...
    database.TotalLearned;

database.AIStatistics.FeatureCount = ...
    database.FeatureLength;

database.AIStatistics.FeatureVersion = ...
    database.FeatureVersion;

database.AIStatistics.DatabaseSize = ...
    size(database.FeatureMatrix,1);

database.AIStatistics.LastModelUpdate = ...
    datetime('now');

%% ============================================================
% Normalize Feature Vector
%% ============================================================

normalizedFeatures = ...
    (features - database.FeatureMean) ./ database.FeatureStd;

record.NormalizedFeatures = ...
    normalizedFeatures;

%% ============================================================
% Similarity Search
%% ============================================================

if database.TotalImages > 1

    similarity = ...
        findSimilarWelds( ...
        features,...
        database);

    record.Similarity = similarity;

%% --------------------------------------------------------
% Anomaly Detection
%% --------------------------------------------------------

anomaly = ...
    calculateAnomalyScore( ...
        similarity,...
        database);

record.Anomaly = anomaly;

record.AnomalyScore = anomaly.Score;

record.Confidence = anomaly.Confidence;

record.Prediction = anomaly.Label;

%% --------------------------------------------------------
% Explain AI Decision
%% --------------------------------------------------------

record.Explanation = ...
    explainPrediction( ...
        features,...
        database);

record.Report = ...
    generateInspectionReport( ...
        record,...
        database);

else

    %% --------------------------------------------------------
    % Reference Weld
    %% --------------------------------------------------------

    record.Similarity = struct();

    record.Similarity.Index = [];

    record.Similarity.Distance = [];

    record.Similarity.Score = [];

    record.Anomaly = struct();

    record.Anomaly.Score = 0;

    record.Anomaly.Confidence = 100;

    record.Anomaly.Label = "REFERENCE";

    record.AnomalyScore = 0;

    record.Confidence = 100;

    record.Prediction = "REFERENCE";

    record.Explanation = [];
    %% --------------------------------------------------------
    % Generate Report
    %% --------------------------------------------------------

    record.Report = ...
        generateInspectionReport( ...
            record,...
            database);

end

%% ------------------------------------------------------------
% Add Record to Database
%% ------------------------------------------------------------

if isempty(database.Records)

    database.Records = record;

else

    database.Records(end+1) = record;

end

%% ------------------------------------------------------------
% Update Database Statistics
%% ------------------------------------------------------------

database.TotalImages = numel(database.Records);

database.TotalLearned = database.TotalLearned + 1;

database.FeatureLength = length(features);

database.FeatureVersion = record.FeatureVersion;

%% ------------------------------------------------------------
% Auto Save
%% ------------------------------------------------------------

if database.Settings.AutoSave

    saveDatabase(database);

end

%% ============================================================
% Automatic Dataset Export
%% ============================================================

exportDataset(database);

%% ------------------------------------------------------------
% Return Results
%% ------------------------------------------------------------

results.Success = true;

results.Message = ...
    "Image successfully learned.";

results.Database = ...
    database;

results.Record = ...
    record;

end

%% ============================================================
function results = inspectMode( ...
                    roiImage,...
                    metadata,...
                    database,...
                    results)

%% ------------------------------------------------------------
% System Health
%% ------------------------------------------------------------

results.SystemHealth = ...
    systemHealthCheck();

%% ------------------------------------------------------------
% Load Deployment Model
%% ------------------------------------------------------------

try

    model = ...
        selectDeploymentModel();

catch

    results.Success = true;

    results.Message = ...
        "No trained AI model available.";

    results.Prediction = "MODEL NOT TRAINED";

    results.Confidence = 0;

    results.Classification = [];

    results.Record = [];

    results.Features = getMLFeatures(roiImage,metadata);

    return;

end 

%% ------------------------------------------------------------
% Standardize Image
%% ------------------------------------------------------------

standardROI = ...
    standardizeImage(roiImage);

%% ------------------------------------------------------------
% Generate Feature Images
%% ------------------------------------------------------------

featureImages = ...
    generateFeatureImages( ...
        standardROI);

%% ------------------------------------------------------------
% Extract Features
%% ------------------------------------------------------------

imageFeatures = ...
    extractFeatures( ...
        standardROI,...
        featureImages);

mlFeatures = ...
    getMLFeatures( ...
        roiImage,...
        metadata);

features = ...
    [imageFeatures(:); mlFeatures(:)]';

%% ------------------------------------------------------------
% Random Forest Prediction
%% ------------------------------------------------------------

prediction = ...
    classifyWeld( ...
        features,...
        model);

%% ------------------------------------------------------------
% Similarity Search
%% ------------------------------------------------------------

similarity = ...
    findSimilarWelds( ...
        features,...
        database);

%% ------------------------------------------------------------
% Anomaly Detection
%% ------------------------------------------------------------

anomaly = ...
    calculateAnomalyScore( ...
        similarity,...
        database);

%% ------------------------------------------------------------
% Explain Prediction
%% ------------------------------------------------------------

explanation = ...
    explainPrediction( ...
        features,...
        database);

%% ------------------------------------------------------------
% Hybrid AI Decision
%% ------------------------------------------------------------

prediction = ...
    fusePrediction( ...
        prediction,...
        anomaly);

%% ------------------------------------------------------------
% Update AI Decision Analysis
%% ------------------------------------------------------------

prediction.DecisionQuality = ...
    decisionQuality( ...
        prediction.Confidence);

prediction.Risk = ...
    assessPredictionRisk( ...
        prediction.Confidence);

prediction.Recommendation = ...
    generateAIRecommendation( ...
        prediction.Label,...
        prediction.Confidence);

%% ------------------------------------------------------------
% Temporary Inspection Record
%% ------------------------------------------------------------

record = struct();

record.Features = features;

record.TimeStamp = datetime('now');

record.RandomForestPrediction = prediction.Label;
record.RandomForestConfidence = prediction.Confidence;

record.Anomaly = anomaly;
record.AnomalyLabel = anomaly.Label;

record.ID = NaN;

record.Prediction = prediction.Label;

record.Confidence = prediction.Confidence;

record.DecisionQuality = ...
    prediction.DecisionQuality;

record.Risk = ...
    prediction.Risk;

record.RecommendationAI = ...
    prediction.Recommendation;

record.ConfidenceAnalysis = ...
    prediction.ConfidenceAnalysis;

record.AnomalyScore = anomaly.Score;

record.ClassProbability = prediction.Score;

record.ClassNames = prediction.ClassNames;

record.Status = "INSPECTED";

record.Explanation = explanation;

record.Similarity = similarity;

record.Report = ...
    generateInspectionReport( ...
        record,...
        database);

%% ------------------------------------------------------------
% Update Database Statistics
%% ------------------------------------------------------------

database.TotalInspections = ...
    database.TotalInspections + 1;

if database.Settings.AutoSave

    saveDatabase(database);

end

%% ------------------------------------------------------------
% Return
%% ------------------------------------------------------------

results.Success = true;

results.Database = database;

results.Features = features;

results.Prediction = prediction.Label;

results.Confidence = prediction.Confidence;

results.Classification = prediction;

results.Similarity = similarity;

results.Anomaly = anomaly;

results.Explanation = explanation;

results.Report = record.Report;

results.Record = record;

results.Message = ...
    "Inspection completed using Random Forest.";

end

%% ============================================================
% VERIFY MODEL
%% ============================================================

function verification = verifyModel(model)

verification = struct();

verification.Valid = true;

verification.Messages = {};

if isempty(model.Classifier)

    verification.Valid = false;

    verification.Messages{end+1} = ...
        "Classifier missing.";

end

if isempty(model.FeatureNames)

    verification.Valid = false;

    verification.Messages{end+1} = ...
        "Feature names missing.";

end

if isempty(model.Mean)

    verification.Valid = false;

    verification.Messages{end+1} = ...
        "Normalization mean missing.";

end

if isempty(model.Std)

    verification.Valid = false;

    verification.Messages{end+1} = ...
        "Normalization std missing.";

end

if ~isfield(model,"Evaluation")

    verification.Valid = false;

    verification.Messages{end+1} = ...
        "Evaluation missing.";

end

end

%% ============================================================
% MODEL INFORMATION
%% ============================================================

function info = modelInformation(model)

info = struct();

info.Version = model.Version;

info.Algorithm = model.Algorithm;

info.Engine = model.Engine;

info.EngineVersion = model.EngineVersion;

info.Trained = model.Trained;

info.NumberOfTrees = model.NumTrees;

info.FeatureCount = numel(model.FeatureNames);

info.FeatureNames = model.FeatureNames;

info.Classes = model.ClassNames;

info.Normalization = model.Normalization;

if isfield(model,"Evaluation")

    info.Accuracy = ...
        model.Evaluation.Accuracy;

else

    info.Accuracy = NaN;

end

if isfield(model,"CrossValidation")

    info.CrossValidation = ...
        model.CrossValidation.MeanAccuracy;

else

    info.CrossValidation = NaN;

end

end

%% ============================================================
% PRINT MODEL INFORMATION
%% ============================================================

function printModelInformation(model)

info = modelInformation(model);

disp(" ");

disp("========================================");

disp(" IWLE MODEL INFORMATION ");

disp("========================================");

fprintf("Version           : %s\n",char(string(info.Version)));

fprintf("Algorithm         : %s\n", char(string(info.Algorithm)));

fprintf("Accuracy          : %.2f%%\n",info.Accuracy);

fprintf("Cross Validation  : %.2f%%\n",info.CrossValidation);

fprintf("Trees             : %d\n",info.NumberOfTrees);

fprintf("Features          : %d\n",info.FeatureCount);

fprintf("Engine            : %s\n", char(string(info.Engine)));

fprintf("Engine Version    : %s\n", char(string(info.EngineVersion)));

fprintf("Trained           : %s\n", char(string(info.Trained)));

disp(" ");

disp("Classes:");

disp(info.Classes);

disp(" ");

end

%% ============================================================
% MODEL INTEGRITY
%% ============================================================

function integrity = modelIntegrity(model)

integrity = struct();

integrity.Pass = true;

integrity.Errors = {};

n = numel(model.FeatureNames);

if length(model.Mean) ~= n

    integrity.Pass = false;

    integrity.Errors{end+1} = ...
        "Mean vector length mismatch.";

end

if length(model.Std) ~= n

    integrity.Pass = false;

    integrity.Errors{end+1} = ...
        "Standard deviation vector length mismatch.";

end

if any(isnan(model.Mean))

    integrity.Pass = false;

    integrity.Errors{end+1} = ...
        "Mean contains NaN.";

end

if any(isnan(model.Std))

    integrity.Pass = false;

    integrity.Errors{end+1} = ...
        "Standard deviation contains NaN.";

end

if model.NumTrees <= 0

    integrity.Pass = false;

    integrity.Errors{end+1} = ...
        "Invalid number of trees.";

end

if isempty(model.Classifier)

    integrity.Pass = false;

    integrity.Errors{end+1} = ...
        "Classifier missing.";

end

end

%% ============================================================
% ENGINE INFORMATION
%% ============================================================

function engine = engineInformation()

engine = struct();

engine.Name = "IWLE";

engine.Version = "2.0";

engine.Author = "Sagar";

engine.Classifier = "Random Forest";

engine.Created = datetime('now');

engine.Features = 59;

engine.Description = ...
    "Intelligent Weld Learning Engine";

end

%% ============================================================
% PRINT ENGINE INFORMATION
%% ============================================================

function printEngineInformation()

engine = engineInformation();

disp(" ");

disp("====================================");

disp(" IWLE ENGINE ");

disp("====================================");

fprintf("Name        : %s\n",engine.Name);

fprintf("Version     : %s\n",engine.Version);

fprintf("Classifier  : %s\n",engine.Classifier);

fprintf("Features    : %d\n",engine.Features);

fprintf("Description : %s\n",engine.Description);

disp(" ");

end

%% ============================================================
function results = updateMode(~,~,database,results)

database.TotalUpdates = database.TotalUpdates + 1;

if database.Settings.AutoSave
    saveDatabase(database);
end

results.Success = true;
results.Message = "Update framework ready.";
results.Database = database;

end

%% ============================================================
function results = databaseMode(database,results)

results.Success = true;

results.Message = ...
    "Database loaded.";

results.Database = ...
    database;

results.DatasetBrowser = ...
    browseDataset(database);

results.Statistics.TotalImages = database.TotalImages;
results.Statistics.TotalLearned = database.TotalLearned;
results.Statistics.TotalInspections = database.TotalInspections;
results.Statistics.TotalUpdates = database.TotalUpdates;

end

%% ============================================================
% TRAIN MODE
%% ============================================================

function results = trainMode(database,results)

results.SystemHealth = ...
    systemHealthCheck();

config = loadConfiguration();

training = ...
    prepareTrainingDataset(database);

if ~training.Ready

    results.Success = false;

    results.Validation = ...
        training.Validation;

    results.Message = ...
        "Dataset not ready.";

    return;

end

training = ...
    splitDataset( ...
        training,...
        config.TrainRatio);

training = ...
    normalizeDataset(training);

parameters = ...
    optimizeRandomForest(training);

model = ...
    trainRandomForest( ...
        training,...
        parameters);

evaluation = ...
    evaluateRandomForest(training,model);

crossValidation = ...
    crossValidateRandomForest( ...
        training,...
        parameters,...
        config.CrossValidationFolds);

results.CrossValidation = ...
    crossValidation;

model.CrossValidation = ...
    crossValidation;

importance = ...
    analyzeFeatureImportance(model);

results.FeatureImportance = ...
    importance;

results.FeatureSummary = ...
    featureImportanceSummary(importance);

model.FeatureAnalysis = ...
    importance;

model.FeatureSummary = ...
    results.FeatureSummary;

results.Evaluation = ...
    evaluation;

model.Evaluation = ...
    evaluation;

model.Accuracy = evaluation.Accuracy;

model.BalancedAccuracy = ...
    evaluation.BalancedAccuracy;

model.Precision = ...
    evaluation.MacroPrecision;

model.Recall = ...
    evaluation.MacroRecall;

model.F1Score = ...
    evaluation.MacroF1;

model.Kappa = ...
    evaluation.Kappa;

model.ConfusionMatrix = ...
    evaluation.ConfusionMatrix;

model.ClassAccuracy = ...
    evaluation.ClassAccuracy;

model.ClassNames = ...
    evaluation.Classes;

model.Grade = ...
    evaluation.Grade;

%% ------------------------------------------------------------
% Model Metadata
%% ------------------------------------------------------------

model.EngineVersion = ...
    training.EngineVersion;

%% ============================================================
% VERIFY TRAINED MODEL
%% ============================================================

verification = verifyModel(model);

if ~verification.Valid

    error(strjoin(verification.Messages,newline));

end

integrity = modelIntegrity(model);

if ~integrity.Pass

    error("%s", strjoin(string(integrity.Errors), newline));

end

%% ============================================================
% PRINT MODEL INFORMATION
%% ============================================================

printModelInformation(model);

printEngineInformation();

saveMLModel(model);

results.Training = training;

results.Model = model;

results.ModelType = model.Type;

results.NumberOfTrees = model.NumTrees;

results.Success = true;

results.Message = ...
    "Random Forest trained successfully.";

end

%% ============================================================
% STANDARDIZE IMAGE
%
% Creates a standardized ROI for AI processing.
%% ============================================================

function standard = standardizeImage(roiImage)

%% Convert to Double

roiImage = im2double(roiImage);

%% Convert RGB

if size(roiImage,3)==3

    gray = rgb2gray(roiImage);

else

    gray = roiImage;

end

%% Remove NaN

gray(isnan(gray)) = 0;

%% Normalize

gray = mat2gray(gray);

%% Resize

targetSize = [256 256];

gray = imresize( ...
    gray,...
    targetSize,...
    'bicubic');

%% Median Filter

gray = medfilt2( ...
    gray,...
    [3 3]);

%% Adaptive Histogram Equalization

gray = adapthisteq( ...
    gray,...
    'ClipLimit',0.02,...
    'NumTiles',[8 8]);

%% Bilateral Filter

try

    gray = imbilatfilt(gray);

catch

end

%% Sharpen

gray = imsharpen( ...
    gray,...
    'Radius',2,...
    'Amount',1);

standard = gray;

end

%% ============================================================
% GENERATE FEATURE IMAGES
%
% Generates image representations used by multiple feature
% extractors.
%% ============================================================

function featureImages = generateFeatureImages(img)

featureImages = struct();

featureImages.Gray = img;

%% Gradient

[Gmag,Gdir] = imgradient(img);

featureImages.GradientMagnitude = mat2gray(Gmag);

featureImages.GradientDirection = Gdir;

%% Sobel

featureImages.Sobel = edge( ...
    img,...
    'Sobel');

%% Canny

featureImages.Canny = edge( ...
    img,...
    'Canny');

%% Laplacian

H = fspecial('laplacian',0.2);

featureImages.Laplacian = ...
    imfilter( ...
    img,...
    H,...
    'replicate');

%% Local Entropy

featureImages.Entropy = ...
    entropyfilt(img);

%% Local Standard Deviation

featureImages.Std = ...
    stdfilt(img);

end

%% ============================================================
% EXTRACT FEATURES
%
% Phase 1B Part 2
%
% Creates the first AI feature vector.
%% ============================================================

function features = extractFeatures( ...
    standardROI,...
    featureImages)

features = [];

%% ============================================================
% INTENSITY FEATURES
%% ============================================================

img = standardROI;

features(end+1) = mean(img(:));

features(end+1) = median(img(:));

features(end+1) = std(img(:));

features(end+1) = var(img(:));

features(end+1) = min(img(:));

features(end+1) = max(img(:));

features(end+1) = range(img(:));

features(end+1) = entropy(img);

features(end+1) = skewness(img(:));

features(end+1) = kurtosis(img(:));

%% ============================================================
% HISTOGRAM FEATURES
%% ============================================================

[counts,~] = imhist(img);

counts = counts ./ sum(counts);

features(end+1) = max(counts);

features(end+1) = mean(counts);

features(end+1) = std(counts);

features(end+1) = entropy(counts);

%% ============================================================
% GRADIENT FEATURES
%% ============================================================

G = featureImages.GradientMagnitude;

features(end+1) = mean(G(:));

features(end+1) = std(G(:));

features(end+1) = max(G(:));

features(end+1) = median(G(:));

%% ============================================================
% EDGE FEATURES
%% ============================================================

BW = featureImages.Canny;

features(end+1) = nnz(BW);

features(end+1) = ...
    nnz(BW)/numel(BW);

CC = bwconncomp(BW);

features(end+1) = CC.NumObjects;

%% ============================================================
% LOCAL ENTROPY
%% ============================================================

E = featureImages.Entropy;

features(end+1) = mean(E(:));

features(end+1) = std(E(:));

%% ============================================================
% LOCAL STD
%% ============================================================

S = featureImages.Std;

features(end+1) = mean(S(:));

features(end+1) = std(S(:));

%% ============================================================
% IMAGE SIZE
%% ============================================================

features(end+1) = size(img,1);

features(end+1) = size(img,2);

features(end+1) = ...
    size(img,2)/size(img,1);


%% ============================================================
% GLCM TEXTURE FEATURES
%% ============================================================

glcm = graycomatrix( ...
    im2uint8(img),...
    'Offset',...
    [0 1]);

stats = graycoprops( ...
    glcm,...
    {'Contrast',...
     'Correlation',...
     'Energy',...
     'Homogeneity'});

features(end+1) = stats.Contrast;

features(end+1) = stats.Correlation;

features(end+1) = stats.Energy;

features(end+1) = stats.Homogeneity;

%% ============================================================
% FFT FEATURES
%% ============================================================

F = fft2(img);

F = abs(F);

features(end+1) = mean(F(:));

features(end+1) = std(F(:));

features(end+1) = max(F(:));

features(end+1) = median(F(:));

%% ============================================================
% SHAPE FEATURES
%% ============================================================

BW = imbinarize(img);

BW = bwareafilt(BW,1);

stats = regionprops( ...
    BW,...
    'Area',...
    'Perimeter',...
    'Eccentricity',...
    'Solidity',...
    'Extent');

if ~isempty(stats)

    features(end+1)=stats.Area;

    features(end+1)=stats.Perimeter;

    features(end+1)=stats.Eccentricity;

    features(end+1)=stats.Solidity;

    features(end+1)=stats.Extent;

else

    features(end+(1:5)) = 0;

end

%% ============================================================
% GRADIENT ORIENTATION
%% ============================================================

theta = featureImages.GradientDirection;

features(end+1)=mean(theta(:));

features(end+1)=std(theta(:));

features(end+1)=median(theta(:));

end

%% ============================================================
% FIND SIMILAR WELDS
%
% Returns the K nearest welds in feature space.
%% ============================================================

function similarity = findSimilarWelds(features,database,K)

config = loadConfiguration();

if nargin < 3

    K = config.NumberOfNeighbours;

end

similarity = struct();

similarity.Index = [];
similarity.Distance = [];
similarity.Score = [];

if isempty(database.FeatureMatrix)
    return;
end

%% Normalize Query

query = ...
    (features - database.FeatureMean) ...
    ./ database.FeatureStd;

%% Normalize Database

db = ...
    (database.FeatureMatrix - database.FeatureMean) ...
    ./ database.FeatureStd;

%% Euclidean Distance

distance = ...
    sqrt(sum((db-query).^2,2));

%% Sort

[distance,index] = sort(distance);

%% Remove identical weld

if ~isempty(distance)

    if distance(1) < 1e-10

        distance(1) = [];

        index(1) = [];

    end

end

K = min(K,length(index));

similarity.Index = index(1:K);

similarity.Distance = distance(1:K);

%% Similarity Score

score = exp(-distance(1:K));

similarity.Score = ...
    100 * score;

end

%% ============================================================
% CALCULATE ANOMALY SCORE
%
% Computes anomaly score from similarity distances.
%% ============================================================

function anomaly = calculateAnomalyScore(similarity,database)

anomaly = struct();

anomaly.Score = 1;

anomaly.Confidence = 0;

anomaly.Label = "UNKNOWN";

if isempty(similarity.Distance)

    return;

end

%% ------------------------------------------------------------
% Mean Distance
%% ------------------------------------------------------------

meanDistance = mean(similarity.Distance);

%% ------------------------------------------------------------
% Adaptive AI Model
%% ------------------------------------------------------------

if ~isfield(database,'AnomalyModel') || ...
   isempty(database.AnomalyModel)

    % Early learning stage
    score = 1 - exp(-meanDistance);

else

    mu = database.AnomalyModel.MeanDistance;

    sigma = database.AnomalyModel.StdDistance;

    if sigma < eps
        sigma = eps;
    end

    % Z-score relative to learned database
    z = (meanDistance - mu) / sigma;

    % Logistic mapping to [0,1]
    score = 1 / (1 + exp(-z));

end

score = max(0,min(score,1));

%% ------------------------------------------------------------
% Confidence
%% ------------------------------------------------------------

confidence = (1-score) * 100;

%% ------------------------------------------------------------
% Decision
%% ------------------------------------------------------------

config = loadConfiguration();

if score < config.NormalThreshold

    label = "REFERENCE";

elseif score < config.WarningThreshold

    label = "FAMILIAR";

elseif score < config.CriticalThreshold

    label = "UNUSUAL";

else

    label = "NOVEL";

end

%% ------------------------------------------------------------
% Store
%% ------------------------------------------------------------

anomaly.Score = score;

anomaly.Confidence = confidence;

anomaly.Label = label;

end

%% ============================================================
% UPDATE ANOMALY MODEL
%
% Learns the distribution of similarity distances.
%% ============================================================

function database = updateAnomalyModel(database)

if size(database.FeatureMatrix,1) < 5

    database.AnomalyModel = [];

    return;

end

N = size(database.FeatureMatrix,1);

distances = zeros(N,1);

for i = 1:N

    db = (database.FeatureMatrix - database.FeatureMean) ...
     ./ database.FeatureStd;

    query = db(i,:);

    d = sqrt(sum((db-query).^2,2));

    d(d==0) = [];

    distances(i) = mean(mink(d,min(5,length(d))));

end

database.AnomalyModel.MeanDistance = mean(distances);

database.AnomalyModel.StdDistance = std(distances);

database.AnomalyModel.ReferenceDistances = distances;

end

%% ============================================================
% FEATURE CONTRIBUTION ANALYSIS
%
% Finds the features that contributed most to the anomaly.
%% ============================================================

function contribution = explainPrediction(features,database)

contribution = struct();

contribution.Index = [];
contribution.Value = [];
contribution.Name = {};

if isempty(database.FeatureMean)

    return;

end

%% Absolute Difference

difference = abs(features - database.FeatureMean);

%% Rank

[value,index] = sort(difference,'descend');

N = min(5,length(index));

contribution.Index = index(1:N);

contribution.Value = value(1:N);

%% ------------------------------------------------------------
% Feature Names
%% ------------------------------------------------------------

names = cell(1,N);

for k = 1:N

    idx = index(k);

    if isfield(database,'FeatureNames') && ...
       idx <= numel(database.FeatureNames)

        names{k} = database.FeatureNames{idx};

    else

        names{k} = sprintf( ...
            'ML Feature %d', ...
            idx - numel(database.FeatureNames));

    end

end

contribution.Name = names;

end

%% ============================================================
% GENERATE AI REASONING
%% ============================================================

function reasoning = generateReasoning(record)

if isempty(record.Explanation)

    reasoning = ...
        "Insufficient data available.";

    return;

end

reasoning = ...
    "AI decision is primarily influenced by:" + newline + newline;

for k = 1:length(record.Explanation.Name)

    reasoning = reasoning + ...
        "• " + string(record.Explanation.Name{k});

    if k < length(record.Explanation.Name)

        reasoning = reasoning + newline;

    end

end

end

%% ============================================================
% GENERATE INSPECTION REPORT
%
% Creates a complete explainable AI inspection report.
%% ============================================================

function report = generateInspectionReport(record,database)

report = struct();

%% ============================================================
% Basic Information
%% ============================================================

report.TimeStamp = datetime('now');

report.Engine = "IWLE";

report.Version = "2.0";

report.Generated = datetime('now');

report.ImageID = record.ID;

report.Status = record.Status;

%% ============================================================
% AI Decision
%% ============================================================

report.Prediction = record.Prediction;

report.Confidence = record.Confidence;

report.DecisionQuality = ...
    decisionQuality(record.Confidence);

report.Risk = ...
    assessPredictionRisk(record.Confidence);

report.RecommendationAI = ...
    generateAIRecommendation( ...
        record.Prediction,...
        record.Confidence);

report.AnomalyScore = record.AnomalyScore;

report.AnomalyLabel = record.AnomalyLabel;

report.RandomForestConfidence = ...
    record.RandomForestConfidence;

%% ============================================================
% Similarity Results
%% ============================================================

report.TopMatches = ...
    buildSimilarityReport( ...
        record.Similarity,...
        database);

%% ============================================================
% Explanation
%% ============================================================

report.TopFeatures = record.Explanation;

%% ============================================================
% AI Reasoning
%% ============================================================

report.Reasoning = ...
    generateReasoning(record);

%% ============================================================
% Recommendation
%% ============================================================

switch record.Prediction

    case "REFERENCE"

        recommendation = ...
            "Reference weld stored for AI learning.";

        priority = "INFO";

    case "FAMILIAR"

        recommendation = ...
            "No significant deviation detected.";

        priority = "LOW";

    case "UNUSUAL"

        recommendation = ...
            "Manual inspection recommended before acceptance.";

        priority = "MEDIUM";

    case "NOVEL"

        recommendation = ...
            "Potential anomaly detected. Immediate review recommended.";

        priority = "HIGH";

    otherwise

        recommendation = ...
            "No recommendation available.";

        priority = "UNKNOWN";

end

report.Recommendation = recommendation;

report.Priority = priority;

%% ============================================================
% Database Information
%% ============================================================

report.DatabaseSize = database.TotalImages;

report.FeatureCount = database.FeatureLength;

report.FeatureVersion = database.FeatureVersion;

%% ============================================================
% AI Statistics
%% ============================================================

if isfield(database,'AIStatistics')

    report.AIStatistics = database.AIStatistics;

%% ============================================================
% Dataset Information
%% ============================================================

if isfield(database,'Dataset')

    report.Dataset = database.Dataset;

else

    report.Dataset = [];

end

else

    report.AIStatistics = [];

end

end

%% ============================================================
% BUILD SIMILARITY REPORT
%% ============================================================

function matches = buildSimilarityReport(similarity,database)

matches = struct([]);

if isempty(similarity.Index)
    return;
end

for k = 1:length(similarity.Index)

    idx = similarity.Index(k);

    if idx > length(database.Records)
        continue;
    end

    r = database.Records(idx);

    matches(k).Rank = k;
    matches(k).ImageID = r.ID;
    matches(k).Similarity = similarity.Score(k);
    matches(k).Distance = similarity.Distance(k);
    matches(k).Prediction = r.Prediction;
    matches(k).Status = r.Status;
    matches(k).TimeStamp = r.TimeStamp;
    matches(k).Confidence = r.Confidence;

    matches(k).AnomalyScore = r.AnomalyScore;

    if isfield(r,'Remarks')
        matches(k).Remarks = r.Remarks;
    else
        matches(k).Remarks = "";
    end

end

end

%% ============================================================
% ASSIGN LABEL
%% ============================================================

function database = assignLabel( ...
    database,...
    imageID,...
    label,...
    operator,...
    remarks)

if nargin < 4
    operator = "";
end

if nargin < 5
    remarks = "";
end

idx = find([database.Records.ID] == imageID,1);

if isempty(idx)

    error("IWLE:RecordNotFound");

end

database.Records(idx).Label = upper(string(label));

database.Records(idx).Operator = operator;

database.Records(idx).Remarks = remarks;

database.Records(idx).Verified = true;

database.Records(idx).LabelTime = datetime('now');

database.Dataset.LastUpdated = datetime('now');

database = refreshDatasetStatistics(database);

end

%% ============================================================
% UPDATE LABEL
%
% Updates an existing image label.
%% ============================================================

function database = updateLabel( ...
    database,...
    imageID,...
    newLabel)

idx = find([database.Records.ID] == imageID,1);

if isempty(idx)

    error("IWLE:RecordNotFound");

end

database.Records(idx).Label = ...
    upper(string(newLabel));

database.Records(idx).LabelTime = ...
    datetime('now');

database.Dataset.LastUpdated = ...
    datetime('now');

database = refreshDatasetStatistics(database);

end

%% ============================================================
% VERIFY RECORD
%% ============================================================

function database = verifyRecord( ...
    database,...
    imageID)

idx = find([database.Records.ID] == imageID,1);

if isempty(idx)

    error("IWLE:RecordNotFound");

end

database.Records(idx).Verified = true;

database.Dataset.LastUpdated = ...
    datetime('now');

database = refreshDatasetStatistics(database);

end

%% ============================================================
% REMOVE LABEL
%% ============================================================

function database = removeLabel( ...
    database,...
    imageID)

idx = find([database.Records.ID] == imageID,1);

if isempty(idx)

    error("IWLE:RecordNotFound");

end

database.Records(idx).Label = ...
    "UNKNOWN";

database.Records(idx).Verified = false;

database.Records(idx).Operator = "";

database.Records(idx).Remarks = "";

database.Records(idx).LabelTime = NaT;

database.Dataset.LastUpdated = ...
    datetime('now');

database = refreshDatasetStatistics(database);

end

%% ============================================================
% LABEL STATISTICS
%% ============================================================

function statistics = getLabelStatistics(database)

statistics = struct();

labels = string({database.Records.Label});

statistics.GOOD = ...
    sum(labels=="GOOD");

statistics.ACCEPTABLE = ...
    sum(labels=="ACCEPTABLE");

statistics.DEFECTIVE = ...
    sum(labels=="DEFECTIVE");

statistics.UNKNOWN = ...
    sum(labels=="UNKNOWN");

statistics.Verified = ...
    sum([database.Records.Verified]);

statistics.Total = ...
    database.TotalImages;

statistics.Completion = ...
    100 * statistics.Verified / ...
    max(1,statistics.Total);

end

%% ============================================================
% DATASET HEALTH
%% ============================================================

function health = datasetHealth(database)

stats = getLabelStatistics(database);

health = struct();

health.Completion = ...
    stats.Completion;

health.ReadyForTraining = ...
    stats.GOOD >= 50 && ...
    stats.DEFECTIVE >= 50;

if health.ReadyForTraining

    health.Status = ...
        "READY";

else

    health.Status = ...
        "COLLECT MORE DATA";

end

health.TotalImages = ...
    stats.Total;

health.LabelledImages = ...
    stats.Verified;

end

%% ============================================================
% DATASET SUMMARY
%% ============================================================

function summary = getDatasetSummary(database)

summary = struct();

labels = string({database.Records.Label});

summary.Total = numel(labels);

summary.GOOD = sum(labels=="GOOD");

summary.ACCEPTABLE = sum(labels=="ACCEPTABLE");

summary.DEFECTIVE = sum(labels=="DEFECTIVE");

summary.UNKNOWN = sum(labels=="UNKNOWN");

summary.Verified = sum([database.Records.Verified]);

summary.LastUpdated = database.Dataset.LastUpdated;

end

%% ============================================================
% DATASET BROWSER
%
% Browse the learned weld database.
%% ============================================================

function browser = browseDataset(database)

browser = struct();

browser.TotalImages = ...
    database.TotalImages;

browser.TotalLearned = ...
    database.TotalLearned;

browser.TotalLabelled = ...
    database.Dataset.LabelledSamples;

browser.TotalUnlabelled = ...
    database.Dataset.UnlabelledSamples;

browser.Version = ...
    database.Version;

browser.Health = ...
    datasetHealth(database);

browser.Summary = ...
    getDatasetSummary(database);

browser.Records(database.TotalImages) = struct();

for k = 1:database.TotalImages

    record = database.Records(k);

    item = struct();

    item.ImageID = record.ID;

    item.TimeStamp = record.TimeStamp;

    item.Label = record.Label;

    item.Prediction = record.Prediction;

    item.Confidence = record.Confidence;

    item.Status = record.Status;

    item.Operator = record.Operator;

    item.Verified = record.Verified;

    item.Remarks = record.Remarks;

    if isfield(record,'Explanation')

        item.TopFeatures = ...
            record.Explanation.Name;

    else

        item.TopFeatures = {};

    end

    browser.Records(k) = item;

end

end

%% ============================================================
% FILTER DATASET
%% ============================================================

function records = filterDataset(database,field,value)

records = struct([]);

count = 0;

for k = 1:database.TotalImages

    record = database.Records(k);

    if isfield(record,field)

        if isequal(record.(field),value)

            count = count + 1;

            records(count) = record;

        end

    end

end

end

%% ============================================================
% REFRESH DATASET STATISTICS
%% ============================================================

function database = refreshDatasetStatistics(database)

%% No records

if isempty(database.Records)

    database.Dataset.TotalSamples = 0;
    database.Dataset.LabelledSamples = 0;
    database.Dataset.UnlabelledSamples = 0;
    database.Dataset.LastUpdated = datetime('now');
    return;

end

%% Upgrade old database records

for k = 1:length(database.Records)

    if ~isfield(database.Records(k),'Label')
        database.Records(k).Label = "UNKNOWN";
    end

    if ~isfield(database.Records(k),'Verified')
        database.Records(k).Verified = false;
    end

    if ~isfield(database.Records(k),'Operator')
        database.Records(k).Operator = "";
    end

    if ~isfield(database.Records(k),'Remarks')
        database.Records(k).Remarks = "";
    end

    if ~isfield(database.Records(k),'LabelTime')
        database.Records(k).LabelTime = NaT;
    end

    if ~isfield(database.Records(k),'Analysis')
        database.Records(k).Analysis = struct();
    end

    if ~isfield(database.Records(k),'Images')
        database.Records(k).Images = struct();
    end

    %----------------------------------------------------------
    % Fracture compatibility
    %----------------------------------------------------------

    if ~isfield(database.Records(k),'FractureDetected')
        database.Records(k).FractureDetected = false;
    end

    if ~isfield(database.Records(k),'FractureArea')
        database.Records(k).FractureArea = 0;
    end

    if ~isfield(database.Records(k),'FractureLength')
        database.Records(k).FractureLength = 0;
    end

    if ~isfield(database.Records(k),'FractureCount')
        database.Records(k).FractureCount = 0;
    end

end
%% Read labels safely

labels = strings(length(database.Records),1);

for k = 1:length(database.Records)

    labels(k) = database.Records(k).Label;

end

%% Update statistics

database.Dataset.TotalSamples = numel(labels);

database.Dataset.LabelledSamples = ...
    sum(labels ~= "UNKNOWN");

database.Dataset.UnlabelledSamples = ...
    sum(labels == "UNKNOWN");

database.Dataset.LastUpdated = datetime('now');

end

%% ============================================================
% VALIDATE DATASET
%
% Checks whether the dataset is suitable for ML training.
%% ============================================================

function validation = validateDataset(database)

validation = struct();

validation.Valid = true;

validation.Messages = {};

validation.TotalImages = ...
    database.TotalImages;

validation.LabelledImages = 0;

validation.FeatureLength = ...
    database.FeatureLength;

if database.FeatureLength == 0

    validation.Valid = false;

    validation.Messages{end+1} = ...
        "Feature extraction has not been completed.";

end

%% ------------------------------------------------------------
% Database Empty
%% ------------------------------------------------------------

if database.TotalImages == 0

    validation.Valid = false;

    validation.Messages{end+1} = ...
        "Database contains no images.";

    return;

end

%% ------------------------------------------------------------
% Feature Matrix
%% ------------------------------------------------------------

if ~isfield(database,'FeatureMatrix') || ...
        isempty(database.FeatureMatrix)

    validation.Valid = false;

    validation.Messages{end+1} = ...
        "Feature matrix missing.";

end

%% ------------------------------------------------------------
% Count Labels
%% ------------------------------------------------------------

good = 0;
acceptable = 0;
defective = 0;
unknown = 0;

for idx = 1:database.TotalImages

    label = database.Records(idx).Label;

    switch upper(string(label))

        case "GOOD"
            good = good + 1;

        case "ACCEPTABLE"
            acceptable = acceptable + 1;

        case "DEFECTIVE"
            defective = defective + 1;

        otherwise
            unknown = unknown + 1;

    end

end

validation.GOOD = good;
validation.ACCEPTABLE = acceptable;
validation.DEFECTIVE = defective;
validation.UNKNOWN = unknown;

validation.ClassBalance = struct();

validation.ClassBalance.GOOD = good;

validation.ClassBalance.ACCEPTABLE = acceptable;

validation.ClassBalance.DEFECTIVE = defective;

validation.ClassBalance.UNKNOWN = unknown;

validation.LabelledImages = ...
    good + acceptable + defective;

%% ------------------------------------------------------------
% Ready?
%% ------------------------------------------------------------

if validation.LabelledImages < 20

    validation.Valid = false;

    validation.Messages{end+1} = ...
        "Not enough labelled images.";

end

if defective == 0

    validation.Messages{end+1} = ...
        "No defective welds available.";

end

if good == 0

    validation.Messages{end+1} = ...
        "No good welds available.";

end

end

%% ============================================================
% PREPARE TRAINING DATASET
%
% Converts database into ML matrices.
%% ============================================================

function training = prepareTrainingDataset(database)

training = struct();

%% ------------------------------------------------------------
% Validation
%% ------------------------------------------------------------

validation = validateDataset(database);

training.Validation = validation;

if ~validation.Valid

    training.Ready = false;

    return;

end

%% ------------------------------------------------------------
% Count Labelled Samples
%% ------------------------------------------------------------

count = 0;

for imageIndex = 1:database.TotalImages

    label = string(database.Records(imageIndex).Label);

    if label ~= "UNKNOWN"

        count = count + 1;

    end

end

%% ------------------------------------------------------------
% Allocate
%% ------------------------------------------------------------

featureLength = database.FeatureLength;

X = zeros(count,featureLength);

Y = strings(count,1);

recordIDs = zeros(count,1);

%% ------------------------------------------------------------
% Build Dataset
%% ------------------------------------------------------------

sampleIndex = 0;

for imageIndex = 1:database.TotalImages

    record = database.Records(imageIndex);

    label = string(record.Label);

    if label == "UNKNOWN"

        continue;

    end

    sampleIndex = sampleIndex + 1;

    X(sampleIndex,:) = record.Features;

    Y(sampleIndex) = label;

    recordIDs(sampleIndex) = record.ID;

end

%% ------------------------------------------------------------
% Store
%% ------------------------------------------------------------

training.Ready = true;

training.NumberOfFeatures = featureLength;

training.FeatureNames = database.FeatureNames;

% ------------------------------------------------------------
% Add placeholder names for additional ML features
% ------------------------------------------------------------
featureLength = database.FeatureLength;
baseFeatureCount = numel(training.FeatureNames);

if baseFeatureCount < featureLength

    for k = baseFeatureCount + 1 : featureLength

        training.FeatureNames{end+1} = ...
            sprintf('ML Feature %d', k - baseFeatureCount);

    end

end

if numel(training.FeatureNames) ~= featureLength

    error( ...
        "IWLE:FeatureNameMismatch", ...
        "Expected %d feature names but found %d.", ...
        featureLength,...
        numel(training.FeatureNames));

end

%% ------------------------------------------------------------
% BALANCE TRAINING DATASET
%% ------------------------------------------------------------

classes = unique(Y);

classCounts = zeros(numel(classes),1);

for i = 1:numel(classes)

    classCounts(i) = sum(Y == classes(i));

end

minCount = min(classCounts);

rng(1);    % Reproducible balancing

balancedCell = cell(numel(classes),1);

for i = 1:numel(classes)

    idx = find(Y == classes(i));

    idx = idx(randperm(numel(idx)));

    balancedCell{i} = idx(1:minCount);

end

balancedIndex = vertcat(balancedCell{:});

balancedIndex = balancedIndex(randperm(numel(balancedIndex)));

X = X(balancedIndex,:);

Y = Y(balancedIndex);

recordIDs = recordIDs(balancedIndex);

count = numel(Y);

training.FeatureMean = ...
    mean(X,1);

training.FeatureStd = ...
    std(X,0,1);

training.FeatureStd( ...
    training.FeatureStd==0)=1;

training.Features = X;

training.Labels = Y;

training.RecordIDs = recordIDs;

training.NumberOfSamples = count;

training.Created = ...
    datetime('now');

training.Version = ...
    "1.0";

training.EngineVersion = "2.0";

training.RandomSeed = 1;

training.ClassNames = classes;

training.OriginalClassCounts = classCounts;

training.BalancedClassCounts = accumarray( ...
    grp2idx(categorical(Y)),1);

training.BalancedSamplesPerClass = minCount;

training.TotalBalancedSamples = count;

training.NumberOfClasses = numel(classes);

end

%% ============================================================
% SPLIT DATASET
%
% Creates training and testing datasets.
%% ============================================================

function training = splitDataset(training,trainRatio)

if nargin < 2

    trainRatio = 0.80;

end

N = training.NumberOfSamples;

if N < 2

    error( ...
        "IWLE:InsufficientSamples", ...
        "At least two labelled samples are required.");

end

rng(1);

index = randperm(N);

trainCount = floor(trainRatio*N);

trainCount = ...
    max(1,trainCount);

trainCount = ...
    min(trainCount,N-1);

trainIndex = index(1:trainCount);

testIndex = index(trainCount+1:end);

training.TrainIndex = trainIndex;

training.TestIndex = testIndex;

training.XTrain = ...
    training.Features(trainIndex,:);

training.YTrain = ...
    training.Labels(trainIndex);

training.XTest = ...
    training.Features(testIndex,:);

training.YTest = ...
    training.Labels(testIndex);

training.TrainingSamples = ...
    size(training.XTrain,1);

training.TestSamples = ...
    size(training.XTest,1);

training.TrainRatio = trainRatio;

training.TestRatio = 1-trainRatio;

end

%% ============================================================
% NORMALIZE DATASET
%% ============================================================

function training = normalizeDataset(training)

mu = mean(training.XTrain,1);

sigma = std(training.XTrain,0,1);

sigma(sigma==0)=1;

training.Mean = mu;

training.Std = sigma;

training.NormalizationParameters = struct();

training.NormalizationParameters.Mean = mu;

training.NormalizationParameters.Std = sigma;

training.Normalization = ...
    "ZScore";

training.XTrain = ...
    (training.XTrain-mu)./sigma;

training.XTest = ...
    (training.XTest-mu)./sigma;

training.Statistics = struct();

training.Statistics.TrainingSamples = ...
    size(training.XTrain,1);

training.Statistics.TestSamples = ...
    size(training.XTest,1);

training.Statistics.Features = ...
    size(training.XTrain,2);

training.Statistics.Classes = ...
    numel(training.ClassNames);

training.Prepared = true;

training.ReadyForTraining = true;

training.PreparedTime = ...
    datetime('now');

training.EngineVersion = ...
    "2.0";

end

%% ============================================================
% OPTIMIZE RANDOM FOREST
%% ============================================================

function parameters = optimizeRandomForest(training)

disp(" ");
disp("========================================");
disp(" OPTIMIZING RANDOM FOREST ");
disp("========================================");

treeOptions = [50 100 150 200 300];
leafOptions = [1 3 5 10];

bestAccuracy = -inf;

parameters = struct();

parameters.NumTrees = 100;
parameters.MinLeafSize = 1;
parameters.BestAccuracy = 0;

X = training.XTrain;
Y = training.YTrain;

for t = 1:length(treeOptions)

    for l = 1:length(leafOptions)

        classifier = TreeBagger( ...
            treeOptions(t), ...
            X, ...
            cellstr(Y), ...
            'Method','classification', ...
            'MinLeafSize',leafOptions(l), ...
            'OOBPrediction','on');

        oob = oobError(classifier);

        accuracy = 100*(1-oob(end));

        fprintf( ...
            'Trees=%3d  Leaf=%2d  Accuracy=%.2f%%\n',...
            treeOptions(t),...
            leafOptions(l),...
            accuracy);

        if accuracy > bestAccuracy

            bestAccuracy = accuracy;

            parameters.NumTrees = treeOptions(t);

            parameters.MinLeafSize = leafOptions(l);

            parameters.BestAccuracy = accuracy;

        end

    end

end

disp(" ");
fprintf("Best Trees      : %d\n",parameters.NumTrees);
fprintf("Best Leaf Size  : %d\n",parameters.MinLeafSize);
fprintf("Best Accuracy   : %.2f%%\n",parameters.BestAccuracy);
disp(" ");

end

%% ============================================================
% TRAIN RANDOM FOREST
%
% Trains the first supervised weld classifier.
%% ============================================================

function model = trainRandomForest(training,parameters)

model = struct();

%% ------------------------------------------------------------
% Train Ensemble
%% ------------------------------------------------------------

classifier = TreeBagger( ...
    parameters.NumTrees,...
    training.XTrain,...
    cellstr(training.YTrain),...
    'Method','classification',...
    'MinLeafSize',parameters.MinLeafSize,...
    'OOBPrediction','On',...
    'OOBPredictorImportance','On');

%% ------------------------------------------------------------
% Store
%% ------------------------------------------------------------

model.Type = "RandomForest";

model.Classifier = classifier;

model.ClassNames = ...
    classifier.ClassNames;

model.FeatureImportance = ...
    classifier.OOBPermutedPredictorDeltaError;

model.OOBError = ...
    oobError(classifier);

model.NumberOfFeatures = ...
    length(training.FeatureNames);

model.TrainingSamples = ...
    training.TrainingSamples;

model.TestSamples = ...
    training.TestSamples;

model.FeatureNames = ...
    training.FeatureNames;

model.Normalization = ...
    training.Normalization;

model.Mean = ...
    training.Mean;

model.Std = ...
    training.Std;

model.NormalizationParameters = ...
    training.NormalizationParameters;

model.Created = ...
    datetime('now');

model.Version = training.Version;

model.NumTrees = parameters.NumTrees;

model.MinLeafSize = parameters.MinLeafSize;

model.Optimization = parameters;

model.Algorithm = "Random Forest";
model.Engine = "IWLE";
model.Trained = datetime('now');

end

%% ============================================================
% EVALUATE RANDOM FOREST
%
% Tests the classifier using the testing dataset.
%% ============================================================

function evaluation = evaluateRandomForest(training,model)

evaluation = struct();

%% ------------------------------------------------------------
% Predict
%% ------------------------------------------------------------

predicted = predict( ...
    model.Classifier,...
    training.XTest);

predicted = string(predicted);

actual = string(training.YTest);

%% ------------------------------------------------------------
% Accuracy
%% ------------------------------------------------------------

accuracy = ...
    mean(predicted == actual) * 100;

evaluation.Accuracy = accuracy;

evaluation.ErrorRate = ...
    100 - accuracy;
%% ------------------------------------------------------------
% Confusion Matrix
%% ------------------------------------------------------------

[classMatrix,classOrder] = ...
    confusionmat(actual,predicted);

evaluation.ConfusionMatrix = classMatrix;

evaluation.Classes = classOrder;

evaluation.NumberOfClasses = numel(classOrder);

%% ------------------------------------------------------------
% Precision / Recall / F1
%% ------------------------------------------------------------

numClasses = ...
    numel(classOrder);

precision = zeros(numClasses,1);

recall = zeros(numClasses,1);

f1 = zeros(numClasses,1);

support = zeros(numClasses,1);

specificity = zeros(numClasses,1);

for c = 1:numClasses

    TP = classMatrix(c,c);

    FP = sum(classMatrix(:,c)) - TP;

    FN = sum(classMatrix(c,:)) - TP;

    TN = sum(classMatrix(:)) - TP - FP - FN;

    precision(c) = ...
        TP / max(TP+FP,1);

    recall(c) = ...
        TP / max(TP+FN,1);

    specificity(c) = ...
        TN / max(TN+FP,1);

    f1(c) = ...
        2 * precision(c) * recall(c) / ...
        max(precision(c)+recall(c),eps);

    support(c) = ...
        sum(classMatrix(c,:));

end

%% ------------------------------------------------------------
% Store Metrics
%% ------------------------------------------------------------

evaluation.Precision = precision;

evaluation.Recall = recall;

evaluation.Specificity = specificity;

evaluation.F1Score = f1;

evaluation.Support = support;

%% ------------------------------------------------------------
% Macro Average
%% ------------------------------------------------------------

evaluation.MacroPrecision = ...
    mean(precision);

evaluation.MacroRecall = ...
    mean(recall);

evaluation.MacroSpecificity = ...
    mean(specificity);

evaluation.MacroF1 = ...
    mean(f1);

%% ------------------------------------------------------------
% Balanced Accuracy
%% ------------------------------------------------------------

evaluation.BalancedAccuracy = ...
    mean(recall) * 100;

%% ------------------------------------------------------------
% Cohen's Kappa
%% ------------------------------------------------------------

N = sum(classMatrix(:));

po = trace(classMatrix) / N;

rowTotals = sum(classMatrix,2);

colTotals = sum(classMatrix,1);

pe = sum(rowTotals .* colTotals') / N^2;

evaluation.Kappa = ...
    (po-pe) / max(1-pe,eps);

%% ------------------------------------------------------------
% Weighted Metrics
%% ------------------------------------------------------------

weights = ...
    support / sum(support);

evaluation.WeightedF1 = ...
    sum(weights .* f1);

evaluation.WeightedPrecision = ...
    sum(weights .* precision);

evaluation.WeightedRecall = ...
    sum(weights .* recall);

%% ------------------------------------------------------------
% Per-Class Accuracy
%% ------------------------------------------------------------

classAccuracy = zeros(numClasses,1);

for c = 1:numClasses

    classAccuracy(c) = ...
        100 * classMatrix(c,c) / ...
        max(sum(classMatrix(c,:)),1);

end

evaluation.ClassAccuracy = classAccuracy;

%% ------------------------------------------------------------
% Store
%% ------------------------------------------------------------

evaluation.Predicted = predicted;

evaluation.Actual = actual;

evaluation.TotalTestSamples = ...
    numel(actual);

evaluation.Correct = ...
    sum(predicted == actual);

evaluation.Incorrect = ...
    sum(predicted ~= actual);

%% ------------------------------------------------------------
% Overall Model Status
%% ------------------------------------------------------------

if evaluation.Accuracy >= 98

    evaluation.Grade = "PRODUCTION READY";

elseif evaluation.Accuracy >= 95

    evaluation.Grade = "EXCELLENT";

elseif evaluation.Accuracy >= 90

    evaluation.Grade = "VERY GOOD";

elseif evaluation.Accuracy >= 85

    evaluation.Grade = "GOOD";

elseif evaluation.Accuracy >= 80

    evaluation.Grade = "ACCEPTABLE";

else

    evaluation.Grade = "NEEDS RETRAINING";

end

end

%% ============================================================
% CROSS VALIDATE RANDOM FOREST
%
% Performs k-fold cross validation.
%% ============================================================

function cv = crossValidateRandomForest( ...
                    training,...
                    parameters,...
                    numFolds)

if nargin < 3

    numFolds = 5;

end

cv = struct();

N = training.NumberOfSamples;

indices = crossvalind('Kfold',N,numFolds);

accuracy = zeros(numFolds,1);

%% ------------------------------------------------------------
% Cross Validation
%% ------------------------------------------------------------

for fold = 1:numFolds

    testIndex = ...
        indices == fold;

    trainIndex = ...
        ~testIndex;

    XTrain = ...
        training.Features(trainIndex,:);

    YTrain = ...
        training.Labels(trainIndex);

    XTest = ...
        training.Features(testIndex,:);

    YTest = ...
        training.Labels(testIndex);

    %% Normalize

    mu = mean(XTrain,1);

    sigma = std(XTrain,0,1);

    sigma(sigma==0)=1;

    XTrain = (XTrain-mu)./sigma;

    XTest = (XTest-mu)./sigma;

    %% Train

    classifier = TreeBagger( ...
            parameters.NumTrees,...
            XTrain,...
            cellstr(YTrain),...
            'Method','classification',...
            'MinLeafSize',parameters.MinLeafSize);

    %% Predict

    prediction = predict(classifier,XTest);

    prediction = string(prediction);

    accuracy(fold) = ...
        mean(prediction==string(YTest))*100;

end

%% ------------------------------------------------------------
% Statistics
%% ------------------------------------------------------------

cv.NumberOfFolds = ...
    numFolds;

cv.Accuracy = ...
    accuracy;

cv.MeanAccuracy = ...
    mean(accuracy);

cv.StdAccuracy = ...
    std(accuracy);

cv.MaximumAccuracy = ...
    max(accuracy);

cv.MinimumAccuracy = ...
    min(accuracy);

cv.BestFold = ...
    find(accuracy==max(accuracy),1);

cv.WorstFold = ...
    find(accuracy==min(accuracy),1);

%% ------------------------------------------------------------
% Confidence Interval
%% ------------------------------------------------------------

margin = ...
    1.96 * cv.StdAccuracy / sqrt(numFolds);

cv.ConfidenceInterval = ...
    [cv.MeanAccuracy-margin,...
     cv.MeanAccuracy+margin];
%% ------------------------------------------------------------
% Stability
%% ------------------------------------------------------------

if cv.StdAccuracy < 2

    cv.Stability = "EXCELLENT";

elseif cv.StdAccuracy < 5

    cv.Stability = "GOOD";

elseif cv.StdAccuracy < 10

    cv.Stability = "MODERATE";

else

    cv.Stability = "POOR";

end

end

%% ============================================================
% ANALYZE FEATURE IMPORTANCE
%
% Ranks all extracted features by Random Forest importance.
%% ============================================================

function importance = analyzeFeatureImportance(model)

importance = struct();

%% ------------------------------------------------------------
% Raw Importance
%% ------------------------------------------------------------

scores = model.FeatureImportance(:);

names = model.FeatureNames(:);

%% ------------------------------------------------------------
% Sort
%% ------------------------------------------------------------

[sortedScores,index] = sort(scores,"descend");

% Ensure every feature has a name
names = names(:);

numScores = numel(scores);
numNames  = numel(names);

if numNames < numScores

    extraNames = cell(numScores-numNames,1);

    for k = 1:(numScores-numNames)

        extraNames{k} = sprintf('ML Feature %d',k);

    end

    names = [names; extraNames];

end

sortedNames = names(index);

%% ------------------------------------------------------------
% Store
%% ------------------------------------------------------------

importance.FeatureNames = sortedNames;

importance.ImportanceScores = sortedScores;

importance.Ranking = index;

importance.NumberOfFeatures = ...
    length(sortedNames);

%% ------------------------------------------------------------
% Top 10 Features
%% ------------------------------------------------------------

N = min(10,length(sortedNames));

importance.TopFeatures = ...
    sortedNames(1:N);

importance.TopScores = ...
    sortedScores(1:N);

importance.MeanImportance = ...
    mean(sortedScores);

importance.MaximumImportance = ...
    max(sortedScores);

importance.MinimumImportance = ...
    min(sortedScores);

%% ------------------------------------------------------------
% Normalized Importance
%% ------------------------------------------------------------

if max(sortedScores) > 0

    importance.NormalizedScores = ...
        sortedScores ./ max(sortedScores);

else

    importance.NormalizedScores = ...
        sortedScores;

end

%% ------------------------------------------------------------
% Importance Category
%% ------------------------------------------------------------

category = strings(length(sortedScores),1);

for k = 1:length(sortedScores)

    value = importance.NormalizedScores(k);

    if value >= 0.80

        category(k) = "VERY HIGH";

    elseif value >= 0.60

        category(k) = "HIGH";

    elseif value >= 0.40

        category(k) = "MEDIUM";

    elseif value >= 0.20

        category(k) = "LOW";

    else

        category(k) = "VERY LOW";

    end

end

importance.Category = category;

%% ------------------------------------------------------------
% Percentage Contribution
%% ------------------------------------------------------------

totalImportance = sum(sortedScores);

if totalImportance > 0

    importance.Percentage = ...
        100 * sortedScores ./ totalImportance;

else

    importance.Percentage = ...
        zeros(size(sortedScores));

end

importance.MostImportantFeature = ...
    importance.TopFeatures(1);

importance.MostImportantScore = ...
    importance.TopScores(1);

end


%% ============================================================
% FEATURE IMPORTANCE SUMMARY
%% ============================================================

function summary = featureImportanceSummary(importance)

N = min(5,importance.NumberOfFeatures);

summary = ...
    "Top AI Features:" + newline;

for k = 1:N

    summary = summary + ...
        sprintf("%d. %s (%.3f | %.1f%%)\n", ...
        k,...
        string(importance.TopFeatures(k)),...
        importance.TopScores(k),...
        importance.Percentage(k));

end

end

%% ============================================================
% ANALYZE PREDICTION CONFIDENCE
%% ============================================================

function confidence = analyzePredictionConfidence(score)

confidence = struct();

maximum = max(score);

confidence.MaximumProbability = ...
    maximum;

confidence.ConfidencePercent = ...
    100 * maximum;

if maximum >= 0.95

    confidence.Level = ...
        "VERY HIGH";

elseif maximum >= 0.85

    confidence.Level = ...
        "HIGH";

elseif maximum >= 0.70

    confidence.Level = ...
        "MEDIUM";

elseif maximum >= 0.50

    confidence.Level = ...
        "LOW";

else

    confidence.Level = ...
        "VERY LOW";

end

end

%% ============================================================
% DECISION QUALITY
%% ============================================================

function quality = decisionQuality(confidence)

if confidence >= 95

    quality = "EXCELLENT";

elseif confidence >= 90

    quality = "VERY GOOD";

elseif confidence >= 80

    quality = "GOOD";

elseif confidence >= 70

    quality = "ACCEPTABLE";

else

    quality = "UNCERTAIN";

end

end

%% ============================================================
% RISK ASSESSMENT
%% ============================================================

function risk = assessPredictionRisk(confidence)

if confidence >= 95

    risk = "VERY LOW";

elseif confidence >= 85

    risk = "LOW";

elseif confidence >= 70

    risk = "MEDIUM";

elseif confidence >= 50

    risk = "HIGH";

else

    risk = "VERY HIGH";

end

end

%% ============================================================
% AI RECOMMENDATION
%% ============================================================

function recommendation = generateAIRecommendation( ...
    prediction,...
    confidence)

switch upper(string(prediction))

    case "GOOD"

        if confidence >= 90

            recommendation = ...
                "Accept weld.";

        else

            recommendation = ...
                "Manual verification recommended.";

        end

    case "ACCEPTABLE"

        recommendation = ...
            "Review according to production standards.";

    case "DEFECTIVE"

        recommendation = ...
            "Reject weld and inspect process.";

    otherwise

        recommendation = ...
            "Prediction uncertain.";

end

end

%% ============================================================
% SAVE MACHINE LEARNING MODEL
%% ============================================================

function saveMLModel(model)

folder = "IWLE_Models";

if ~exist(folder,"dir")

    mkdir(folder);

end

%% ------------------------------------------------------------
% Determine Version
%% ------------------------------------------------------------

files = dir(fullfile(folder,"RandomForest_v*.mat"));

version = length(files) + 1;

%% ------------------------------------------------------------
% Metadata
%% ------------------------------------------------------------

model.Version = version;

model.Trained = datetime('now');

model.Engine = "IWLE";

model.Algorithm = "Random Forest";

filename = sprintf( ...
    "RandomForest_v%03d.mat", ...
    version);

save( ...
    fullfile(folder,filename),...
    "model");

updateModelHistory(model);

updateBestModel(model);

save( ...
    fullfile(folder,"LatestVersion.mat"),...
    "version");

save("IWLE_Model.mat","model");

end

%% ============================================================
% UPDATE MODEL HISTORY
%% ============================================================

function updateModelHistory(model)

historyFile = ...
    "IWLE_Models/ModelHistory.mat";

if exist(historyFile,"file")

    S = load(historyFile);

    history = S.history;

else

    history = struct([]);

end

entry = struct();

entry.Version = model.Version;

entry.Date = model.Trained;

entry.Algorithm = model.Algorithm;

entry.NumberOfTrees = model.NumTrees;

entry.Features = numel(model.FeatureNames);

entry.EngineVersion = model.EngineVersion;

if isfield(model,"Evaluation")

    entry.Accuracy = ...
        model.Evaluation.Accuracy;

else

    entry.Accuracy = NaN;

end

if isfield(model,"CrossValidation")

    entry.CrossValidationAccuracy = ...
        model.CrossValidation.MeanAccuracy;

else

    entry.CrossValidationAccuracy = NaN;

end

if isempty(history)

    history = entry;

else

    history(end+1) = entry;

end

save(historyFile,"history");

end

%% ============================================================
% UPDATE BEST MODEL
%% ============================================================

function updateBestModel(model)

folder = "IWLE_Models";

bestFile = ...
    fullfile(folder,"BestModel.mat");

currentAccuracy = NaN;

if isfield(model,"Evaluation")

    currentAccuracy = ...
        model.Evaluation.Accuracy;

end

saveBest = false;

if ~exist(bestFile,"file")

    saveBest = true;

else

    S = load(bestFile);

    bestModel = S.model;

    if ~isfield(bestModel,"Evaluation")

        saveBest = true;

    elseif currentAccuracy > ...
            bestModel.Evaluation.Accuracy

        saveBest = true;

    end

end

if saveBest

    save(bestFile,"model");

    save("IWLE_Model.mat","model");

end

end

%% ============================================================
% LOAD MODEL HISTORY
%% ============================================================

function history = loadModelHistory()

historyFile = ...
    "IWLE_Models/ModelHistory.mat";

if exist(historyFile,"file")

    S = load(historyFile);

    history = S.history;

else

    history = struct([]);

end

end

%% ============================================================
% COMPARE MODELS
%% ============================================================

function comparison = compareModels()

comparison = struct();

history = loadModelHistory();

comparison.TotalModels = ...
    length(history);

if isempty(history)

    comparison.BestVersion = [];

    return;

end

accuracy = [history.Accuracy];

[bestAccuracy,index] = max(accuracy);

comparison.BestAccuracy = ...
    bestAccuracy;

comparison.BestVersion = ...
    history(index).Version;

comparison.History = ...
    history;

comparison.MeanAccuracy = ...
    mean(accuracy);

comparison.StdAccuracy = ...
    std(accuracy);

comparison.MaximumAccuracy = ...
    max(accuracy);

comparison.MinimumAccuracy = ...
    min(accuracy);

comparison.Improvement = ...
    comparison.MaximumAccuracy - ...
    comparison.MinimumAccuracy;

end

%% ============================================================
% LOAD BEST MODEL
%% ============================================================

function model = loadBestModel()

filename = ...
    fullfile( ...
    "IWLE_Models",...
    "BestModel.mat");

if ~exist(filename,"file")

    error( ...
        "IWLE:BestModelMissing",...
        "Best model not found.");

end

S = load(filename);

model = S.model;

end

%% ============================================================
% SELECT DEPLOYMENT MODEL
%
% Loads the model currently deployed for inspection.
%% ============================================================

function model = selectDeploymentModel()

deployment = ...
    getDeploymentStatus();

fprintf( ...
    "Loading deployed model v%d...\n", ...
    deployment.Version);

model = loadBestModel();

verification = ...
    verifyModel(model);

if ~verification.Valid

    error( ...
        "IWLE:InvalidModel", ...
        strjoin(verification.Messages,newline));

end

end

%% ============================================================
% SYSTEM HEALTH CHECK
%% ============================================================

function health = systemHealthCheck()

health = struct();

%% ------------------------------------------------------------
% Database
%% ------------------------------------------------------------

health.DatabaseExists = ...
    exist("IWLE_Database.mat","file");

%% ------------------------------------------------------------
% Current Model
%% ------------------------------------------------------------

health.ModelExists = ...
    exist("IWLE_Model.mat","file");

%% ------------------------------------------------------------
% Model Folder
%% ------------------------------------------------------------

health.ModelFolder = ...
    exist("IWLE_Models","dir");

%% ------------------------------------------------------------
% Dataset Folder
%% ------------------------------------------------------------

health.DatasetFolder = ...
    exist("IWLE_Dataset","dir");

%% ------------------------------------------------------------
% Ready
%% ------------------------------------------------------------

health.Ready = ...
    health.DatabaseExists && ...
    health.ModelFolder;

health.Time = datetime('now');

end

%% ============================================================
% DEFAULT CONFIGURATION
%% ============================================================

function config = defaultConfiguration()

config = struct();

%% ------------------------------------------------------------
% Machine Learning
%% ------------------------------------------------------------

config.RandomForestTrees = 100;

config.TrainRatio = 0.80;

config.CrossValidationFolds = 5;

%% ------------------------------------------------------------
% Similarity Search
%% ------------------------------------------------------------

config.NumberOfNeighbours = 5;

%% ------------------------------------------------------------
% Anomaly Detection
%% ------------------------------------------------------------

config.NormalThreshold = 0.20;

config.WarningThreshold = 0.40;

config.CriticalThreshold = 0.60;

%% ------------------------------------------------------------
% Image Processing
%% ------------------------------------------------------------

config.StandardImageSize = [256 256];

config.FeatureVersion = "1.1";

%% ------------------------------------------------------------
% Engine
%% ------------------------------------------------------------

config.EngineVersion = "2.0";

config.Project = "IWLE";

end

%% ============================================================
% LOAD CONFIGURATION
%% ============================================================

function config = loadConfiguration()

filename = "IWLE_Config.mat";

if exist(filename,"file")

    S = load(filename);

    config = S.config;

else

    config = defaultConfiguration();

    save(filename,"config");

end

end

%% ============================================================
% SAVE CONFIGURATION
%% ============================================================

function saveConfiguration(config)

save("IWLE_Config.mat","config");

end

%% ============================================================
% GET DEPLOYED MODEL
%% ============================================================

function deployment = getDeploymentStatus()

deployment = struct();

best = loadBestModel();

deployment.Version = ...
    best.Version;

if isfield(best,"Evaluation")

    deployment.Accuracy = ...
        best.Evaluation.Accuracy;

else

    deployment.Accuracy = NaN;

end

deployment.Engine = ...
    best.Engine;

deployment.EngineVersion = ...
    best.EngineVersion;

deployment.Trained = ...
    best.Trained;

deployment.Algorithm = ...
    best.Algorithm;

end

%% ============================================================
% ROLLBACK MODEL
%% ============================================================

function rollbackModel(version)

folder = "IWLE_Models";

filename = sprintf( ...
    "RandomForest_v%03d.mat",...
    version);

path = fullfile(folder,filename);

if ~exist(path,"file")

    error( ...
        "IWLE:Rollback",...
        "Requested model version not found.");

end

S = load(path);

model = S.model;

save( ...
    fullfile(folder,"BestModel.mat"),...
    "model");

save("IWLE_Model.mat","model");

end

%% ============================================================
% PRINT DEPLOYMENT STATUS
%% ============================================================

function printDeploymentStatus()

deployment = ...
    getDeploymentStatus();

disp(" ");

disp("==============================");

disp(" IWLE DEPLOYMENT ");

disp("==============================");

fprintf( ...
    "Version      : %d\n", ...
    deployment.Version);

fprintf( ...
    "Accuracy     : %.2f%%\n", ...
    deployment.Accuracy);

fprintf( ...
    "Engine       : %s\n", ...
    deployment.Engine);

fprintf( ...
    "Engine Ver.  : %s\n", ...
    deployment.EngineVersion);

fprintf( ...
    "Algorithm    : %s\n", ...
    deployment.Algorithm);

disp(" ");

end

%% ============================================================
% PRINT SYSTEM HEALTH
%% ============================================================

function printSystemHealth()

health = systemHealthCheck();

disp(" ");

disp("====================================");

disp(" IWLE SYSTEM HEALTH ");

disp("====================================");

fprintf("Database       : %d\n", ...
    health.DatabaseExists);

fprintf("Model          : %d\n", ...
    health.ModelExists);

fprintf("Model Folder   : %d\n", ...
    health.ModelFolder);

fprintf("Dataset Folder : %d\n", ...
    health.DatasetFolder);

fprintf("Ready          : %d\n", ...
    health.Ready);

disp(" ");

end

%% ============================================================
% STARTUP SELF TEST
%% ============================================================

function startupSelfTest()

printSystemHealth();

disp("Running IWLE self-test...");

try

    model = loadBestModel();

    verifyModel(model);

    disp("Model verification passed.");

catch ME

    warning(ME.message);

end

disp("Self-test complete.");

end

%% ============================================================
% PRINT MODEL HISTORY
%% ============================================================

function printModelHistory()

comparison = ...
    compareModels();

if comparison.TotalModels == 0

    disp("No trained models available.");

    return;

end

disp(" ");

disp("======================================");

disp(" IWLE MODEL HISTORY ");

disp("======================================");

for k = 1:comparison.TotalModels

    h = comparison.History(k);

    fprintf( ...
        "v%03d   %.2f%%\n", ...
        h.Version,...
        h.Accuracy);

end

disp(" ");

fprintf( ...
    "Best Model : v%03d\n", ...
    comparison.BestVersion);

fprintf( ...
    "Accuracy   : %.2f%%\n", ...
    comparison.BestAccuracy);

end

%% ============================================================
% VERIFY MODEL INTEGRITY
%% ============================================================

function status = verifyModelIntegrity(model)

status = true;

required = { ...
    'Classifier',...
    'FeatureNames',...
    'Mean',...
    'Std',...
    'Evaluation'};

for k = 1:length(required)

    if ~isfield(model,required{k})

        status = false;

        return;

    end

end

end

%% ============================================================
% CLASSIFY WELD
%
% Predicts weld quality using the trained Random Forest.
%% ============================================================

function prediction = classifyWeld(features,model)

prediction = struct();

%% ------------------------------------------------------------
% Normalize Feature Vector
%% ------------------------------------------------------------

x = ...
    (features - model.Mean) ./ model.Std;

%% ------------------------------------------------------------
% Predict
%% ------------------------------------------------------------

[label,score] = ...
    predict(model.Classifier,x);

prediction.Label = ...
    string(label);

%% ------------------------------------------------------------
% Confidence
%% ------------------------------------------------------------

prediction.Score = score;

prediction.Confidence = ...
    max(score) * 100;

prediction.ClassNames = ...
    model.ClassNames;

%% ------------------------------------------------------------
% Confidence Analysis
%% ------------------------------------------------------------

prediction.ConfidenceAnalysis = ...
    analyzePredictionConfidence(score);

prediction.DecisionQuality = ...
    decisionQuality( ...
        prediction.Confidence);

prediction.Risk = ...
    assessPredictionRisk( ...
        prediction.Confidence);

prediction.Recommendation = ...
    generateAIRecommendation( ...
        prediction.Label,...
        prediction.Confidence);

end

%% ============================================================
% FUSE PREDICTIONS
%% ============================================================

function prediction = fusePrediction(prediction,anomaly)

if anomaly.Score > 0.80

    prediction.Label = "DEFECTIVE";

    prediction.Confidence = ...
        max(prediction.Confidence,...
            anomaly.Confidence);

elseif anomaly.Score > 0.60

    if prediction.Label == "GOOD"

        prediction.Label = "ACCEPTABLE";

    end

end

prediction.AnomalyScore = ...
    anomaly.Score;

prediction.AnomalyLabel = ...
    anomaly.Label;

end

%% ============================================================
% EXPORT DATASET
%
% Creates a machine learning dataset.
%% ============================================================

function exportDataset(database)

%% ============================================================
% Create Folder
%% ============================================================

folder = "IWLE_Dataset";

if ~exist(folder,"dir")

    mkdir(folder);

end

imageFolder = fullfile(folder,"Images");

if ~exist(imageFolder,"dir")

    mkdir(imageFolder);

end

%% ============================================================
% Dataset Table
%% ============================================================

rowsCell = cell(database.TotalImages,1);

for k = 1:database.TotalImages

    record = database.Records(k);

    row = struct();

    row.ImageID = record.ID;
    row.TimeStamp = string(record.TimeStamp);
    row.Label = string(record.Label);
    row.Prediction = string(record.Prediction);
    row.Confidence = record.Confidence;
    row.Status = string(record.Status);
    row.Operator = string(record.Operator);
    row.Verified = record.Verified;

    features = record.Features;

    for n = 1:length(features)

        if n <= length(database.FeatureNames)
            fieldName = matlab.lang.makeValidName(database.FeatureNames{n});
        else
            fieldName = sprintf("Feature_%02d",n);
        end

        row.(fieldName) = features(n);

    end

    rowsCell{k} = struct2table(row,'AsArray',true);

    %% --------------------------------------------------------
    % Save ROI
    %% --------------------------------------------------------

    if isfield(record,"StandardROI")

        filename = sprintf("ROI_%06d.png",record.ID);

        imwrite(record.StandardROI,...
            fullfile(imageFolder,filename));

    end

end

rows = vertcat(rowsCell{:});

%% ============================================================
% Save CSV
%% ============================================================

writetable( ...
    rows,...
    fullfile(folder,"MasterDataset.csv"));

%% ============================================================
% Save Database
%% ============================================================

save( ...
    fullfile(folder,"DatasetInfo.mat"),...
    "database","-v7.3");

%% ============================================================
% Save Dataset Summary
%% ============================================================

summary = getDatasetSummary(database);

save( ...
    fullfile(folder,"DatasetSummary.mat"),...
    "summary");

end
