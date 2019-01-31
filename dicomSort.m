function dicomSort(studyPath,varargin)
% dicomSort Recursive dicom sorting tool.
%   dicomSort(input) sorts all dicom files for each subject in a study
%   folder.
%
%   dicomSort(input,output) sorts all dicom files in a subject folder and
%   outputs them into a predefined folder.
%
%   Author: Siddhartha Dhiman
%   Email: dhiman@musc.edu
%   First created on 01/28/2019 using MATLAB 2018b
%   Last modified on 01/28/2019 using MATLAB 2018b
%
%   SEE ALSO ...

warning off;
%% Parse Inputs
defaultComp = 'none';
defaultPreserve = true;
expectedLog = {'yes','no'};
expectedComp = {'none','zip','tar','gzip'};
p = inputParser;
addRequired(p,'studyPath',@isstr);
addOptional(p,'output',@isstr);
addParameter(p,'preserve',defaultPreserve,@logical);
addParameter(p,'compression',defaultComp,...
    @(s) any(validatestring(s,expectedComp)));
addOptional(p,'prefix',@isstring);
addOptional(p,'suffix',@isstring);

parse(p,studyPath,varargin{:});

%% Perform Tests
%   Check whether input path exists
if ~isfolder(studyPath)
    error('Input path not found, ensure it exists');
elseif isstr(p.Results.output)
    outPath = p.Results.output;
    if isdir(p.Results.output)
        ;
    else
        mkdir(p.Results.output)
    end
end

%% Tunable Function Variables
studyDir = vertcat(dir(fullfile(studyPath,'**/*')),...
    dir(fullfile(studyPath,'**/*.dcm'))); %   Recursive directory listing
studyDirFolders = dir(studyPath);
rmPattern = {'.','.DS_Store'};   %   Remove files beginning with

%% Clean up Main Study Dir Listing
rmIdx = zeros(1,length(studyDirFolders));
for i = 1:length(studyDirFolders)
    if any(startsWith(studyDirFolders(i).name,'.'));
        rmIdx(i) = 1;
        
    else
        %   If nothing found, don't mark for deletion
        rmIdx(i) = 0;
    end
end
%   Create folder listing for compression
for i = 1:length(studyDirFolders)
    compPaths{i} = fullfile(studyDirFolders(i).folder,...
        studyDirFolders(i).name);
end
nComp = length(compPaths);

%% Clean-up Dicom Directory Listing
rmIdx = zeros(1,length(studyDir));
for i = 1:length(studyDir)
    %  Check for directories
    if studyDir(i).isdir == 1
        rmIdx(i) = 1;
        
        %   Check for files starting with'.'
    elseif any(startsWith(studyDir(i).name,'.'));
        rmIdx(i) = 1;
        
    else
        %   If nothing found, don't mark for deletion
        rmIdx(i) = 0;
    end
end
studyDir(rmIdx ~= 0) = [];   %   Apply deletion filter
nFiles = length(studyDir);
fprintf('Found %d dicom files\n',nFiles);

%% Sort Dicom Files
%   Run in parent parfor for speed
j = 1;
parfor i = 1:nFiles
    try
        tmp = dicominfo(fullfile(studyDir(i).folder,studyDir(i).name));
    catch
        continue
    end
    sortStatus = fprintf('%d/%d: sorting %s',j,length(studyDir),...
        tmp.ProtocolName);
    
    if ~exist(fullfile(outPath,tmp.PatientID,tmp.ProtocolName),'dir')
        mkdir(fullfile(outPath,tmp.PatientID,tmp.ProtocolName));
    else
        ;
    end
    if ~contains(studyDir(i).name,'.dcm')
        newName = [studyDir(i).name '.dcm'];
    else
        newName = studyDir(i).name;
    end
    copyfile(tmp.Filename,fullfile(outPath,tmp.PatientID,...
        tmp.ProtocolName,newName));
    
    fprintf('Sorting %s: %d/%d',tmp.PatientID,i,nFiles);
end

if strcmp(p.Results.compression,'none');
    frintf('Skipping comppression\n');
elseif strcmp(p.Results.compression,'zip')
    fprintf('Zipping files...');
    zip(fullfile(studyPath,'study_original_files.zip'),compPaths);
    fprintf('saved as %s',fullfile(studyPath,'study_original_files.zip\n'));
elseif strcmp(p.Results.compression,'tar')
    fpintf('Tarring files...');
    zip(fullfile(studyPath,'study_original_files.tar'),compPaths);
    fprintf('saved as %s',fullfile(studyPath,'study_original_files.tar\n'));
elseif strcmp(p.Results.compression,'gzip')
    fpintf('Gunziping files...');
    zip(fullfile(studyPath,'study_original_files.tar'),compPaths);
    fprintf('saved as %s',fullfile(studyPath,'study_original_files.gz\n'));
else
    fprintf('Not sure what your compression options are');
end

if ~p.Results.preserve
    fprintf('Not preserving files, removing folders:\n');
    for j = 1:nComp
        fprintf('%d/%d:    %s\n',j,ncomp,...
            fullfile(studyDirFolders(i).folder,studyDirFolders(i).name));
        rmdir(fullfile(studyDirFolders(i).folder,studyDirFolders(i).name),'s');
    end
else
    fprintf('Preserving orignal files\n');
end
    


    
    
end


