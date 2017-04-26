function [dicomList, niiList, outputDir] = convert2Nii(dataDir, outDir, subject)
%CONVERT2NII Convert DICOM images to NIfTI format
%Note the conversion is specific to studies of Fallypride. The function
%excepts the following Directory structure and filename pattern:
%DATA_DIR
%  |---SUBJECT1
%        |---Decay*
%              |---*DY1
%              |     |---PATIENT_ID
%              |                 |---Dicom files 3DFORE*_PT[001-0047].dcm
%              |---*DY2
%              |     |---PATIENT_ID
%              |                 |---Dicom files 3DFORE**_PT[001-0047].dcm
%              |---*DY3
%              |     |---PATIENT_ID
%              |                 |---Dicom files 3DFORE**_PT[001-0047].dcm
%    __________________________________________________________
%    | Epoch | # Volumes | #Slices/Volume| # 3DFORE .dcm files|
%    |-------|-----------|---------------|--------------------|
%    |  DY1  |     28    |        47     |        1316        |
%    |  DY2  |     04    |        47     |         188        |
%    |  DY3  |     03    |        47     |         141        |
%    |  ALL  |     35    |        47     |        1645        |
%    |--------------------------------------------------------|
%   Note: the pattern may be different for exceptions. Example see folder
%   structure for subjects : DND027, DND041, and DND060
% 
%   Inputs:
%   dataDir : Folder containing subject folder structure described above
%   outDir : Folder to which the output files are written. Subject folder
%            is created under this folder
%   subject : Subject folder name 
%
%   Outputs:
%   dicomList : A cell array of filenames of DICOM files
%   niiList   : A cell array of filenames of NifTI files
%   outputDir: Folder where NIfTI files are written
%
%   Example:
%   [dicomList, niiList, outputDir] = 
%   CONVERT2NII('[teba-location-zaldlab-fallypride]/Scan_1/','[out-folder/] ,'DND005')
%
%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%

    [dicomList, niiList, outputDir]=deal([]);
    batchFunction='Convert2Nii';
    % Process spm batch for job
    fprintf('\nProcessing for subject: %s\t%s\n',subject,batchFunction);
  
    % Initialize subject specific variables
    subjectSubDir = 'Decay*/*DY*/*/';
    fileFilter='3DFORE*';
    initObj=initializeVars(dataDir,outDir,subject, subjectSubDir, fileFilter);
    
    % check if the # dcm files in DY1, DY2, and DY3 are as expected
    checkNumberOfDicomFiles(initObj.dicomList);

    % Create output dir
    mkdir(initObj.outDir);

    % Run current job function, passing along subject-specific inputs 
    spm('defaults','PET');
    spm_jobman('initcfg');

    batchJob{1} = createJob(initObj);
    jobOutput = spm_jobman('run', batchJob);

    % Move and rename converted files
    fprintf('\n\t%s : Moving and renaming converted nii files for Subject: %s\n',batchFunction, initObj.subject);
    niiList=moveConvertedFiles(initObj);

    % Other outputs
    dicomList = initObj.dicomList;
    outputDir = initObj.outDir;
    
    % Save output (e.g., matlabbatch) for future reference
    outName = [initObj.outDir,filesep,subject,'_',batchFunction];
    save(outName, 'batchJob');
    save([outName,'_jobOutput'], 'jobOutput');
    
    % Clear Job vars
    clearvars jobs outName batchJob jobOutput harvestedJob
end

% Initialize variables
function [ initObj ] = initializeVars(dataDir, outDir, subject, subjectSubDir, fileFilter)
    %INITIALIZEVARS Initialze variables for the SPM job
    
    % Input
    initObj.baseDir = dataDir;
    initObj.subject = subject;
    
    % Directory information
    initObj.subjectSubDir = subjectSubDir;
    initObj.fileFilter=fileFilter;
    initObj.dataDir = [initObj.baseDir,initObj.subject,filesep,initObj.subjectSubDir,initObj.fileFilter];

    % Change for naming conventions
    initObj = run_exceptions(initObj);

    % Create dicom file list
    initObj.dicomList = getDicomFileList(initObj.dataDir);

    % Output
    initObj.outDir = strcat(outDir,initObj.subject);

end

%% Check number of dicom files
function checkNumberOfDicomFiles(dicomList)
    %    __________________________________________________________
    %    | Epoch | # Volumes | #Slices/Volume| # 3DFORE .dcm files|
    %    |-------|-----------|---------------|--------------------|
    %    |  DY1  |     28    |        47     |        1316        |
    %    |  DY2  |     04    |        47     |         188        |
    %    |  DY3  |     03    |        47     |         141        |
    %    |  ALL  |     35    |        47     |        1645        |
    %    |--------------------------------------------------------|
    c = cell2mat(regexp(dicomList,'.*(?<DY>DY\d).*','once','names'));
    c=[{c.DY}'];
    dy1Files=sum(cell2mat(strfind(c,'DY1')));
    dy2Files = sum(cell2mat(strfind(c,'DY2')));
    dy3Files = sum(cell2mat(strfind(c,'DY3')));
    if ( dy1Files ~= 1316)
        throw(MException('convertNii:checkNumberOfDicomFiles', ['Number of 3DFORE*.dcm files in DY1 must be 1316, but was ', num2str(dy1Files)]));
    elseif ( dy2Files ~= 188)
        throw(MException('convertNii:checkNumberOfDicomFiles', ['Number of 3DFORE*.dcm files in DY2 must be 188, but was ', num2str(dy2Files)]));            
    elseif ( dy3Files ~=141)
        throw(MException('convertNii:checkNumberOfDicomFiles', ['Number of 3DFORE*.dcm files in DY3 must be 141, but was ', num2str(dy3Files)]));                        
    end
       
end

%% Account for naming convention exceptions for subject directories
function initObj = run_exceptions(initObj)
    %RUN_EXCEPTIONS Dir name exceptions
    if ismember(initObj.subject,{'DND027' 'DND037' 'DND041' 'DND060' 'DND062'})
        if isfield(initObj,'dataDir')
            initObj.dataDir = [initObj.baseDir,initObj.subject,filesep,initObj.subject,...
                ' ',upper(initObj.subjectSubDir),initObj.fileFilter];
        end
    end
end

%% Create matlabbatch job for conversion from DICOM to NIfTI
function [ matlabbatch ] = createJob(initVars)
    %CREATEJOB Create SPM matlabbatch job for conversion from DICOM to NIfTI format
    
    matlabbatch.spm.util.dicom.data = initVars.dicomList;
    matlabbatch.spm.util.dicom.root = 'patid';
    matlabbatch.spm.util.dicom.outdir = {initVars.outDir};
    matlabbatch.spm.util.dicom.convopts.format = 'nii';
    matlabbatch.spm.util.dicom.convopts.icedims = 0;
end

%% Move converted files from sub dirs to main dir and rename volumes
function [ niiFiles ] = moveConvertedFiles(initObj)
    %MOVECONVERTEDFILES Move converted files from sub dirs to main dir and
    %rename as volxxxx.nii
    outDir = initObj.outDir;
    subDirMap = containers.Map({'/*DY1*/','/*DY2*/','/*DY3*/'},{0,28,32});
    subDirs = subDirMap.keys;
    niiFiles = {};
    for ii = 1:length(subDirs)
        flist = dir([outDir,filesep,'*',filesep,subDirs{ii},'*.nii']);
        key = subDirs{ii};
        for jj = 1:length(flist)
            currFile = [flist(jj).folder,filesep,flist(jj).name];
            fileparts = strsplit(flist(jj).name,'-');
            volNum = (str2double(fileparts{4})/47)-1 + subDirMap(key);
            newFile = strcat(outDir,filesep,'vol',num2str(volNum,'%04d'),'.nii');
            copyfile(currFile,newFile);
            niiFiles{length(niiFiles)+1,1} = newFile;
        end
    end
    d=dir(outDir);
    subDirIdx= cell2mat(cellfun(@(name,isdir) [~contains(name,'.') && isdir==1], {d.name},{d.isdir},'UniformOutput',false))==1;
    rmdir([outDir,filesep,d(subDirIdx).name],'s');
end

