function [dicomList, niiList, outputDir] = convert2NiiNew(dataDir, outDir, subject)
%CONVERT2NIINEW Convert DICOM images to NIfTI format
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
    setenv('FSLOUTPUTTYPE','NIFTI');
    [dicomList, niiList, outputDir]=deal([]);
    batchFunction='Convert2NiiNew';
    % Process spm batch for job
    fprintf('\nProcessing for subject: %s\t%s\n',subject,batchFunction);
  
    % Initialize subject specific variables
    subjectSubDir = 'Decay*/*DY*/*/';
    fileFilter='3DFORE*';
    initObj=initializeVars(dataDir,outDir,subject, subjectSubDir, fileFilter);
    
    % check if the # dcm files in DY1, DY2, and DY3 are as expected
    checkNumberOfDicomFiles(initObj.dicomList);

    % Create subject output dir
    mkdir(initObj.outDir);
    
    % Use dcm2niix for conversion
    % for DY1, Dy2, ... DY3
    for ii=1:3
        cd(initObj.outDir);
        % Create temp in the output dir
        tempDir=[initObj.outDir filesep 'tempDy' num2str(ii) filesep];
        mkdir(tempDir);
        % for DY1, Dy2, ... DY3
        dcmDir = regexprep(initObj.dataDir, '\*DY\*', ['\*DY' num2str(ii) '\*']);
        %also replace space with '\ ' for command line call
        dcmDir = regexprep(dcmDir,' ','\\ ');
        dcm2nii =  ['dcm2niix -v -s y -z n -f vol_%t_%p -o ' tempDir ' ' dcmDir ];
        disp(dcm2nii)
        system(dcm2nii,'-echo');
        % split the nii file
        fslsplit = ['fslsplit ' tempDir '*3D_FORE*.nii'];
        dyDir=['dy' num2str(ii)];
        mkdir(dyDir);
        cd(dyDir);
        disp(fslsplit)
        system(fslsplit,'-echo');
        %[s,m,mid]=rmdir(tempDir,'s')
    end
    % Move and rename converted files
    cd(initObj.outDir);
    fprintf('\n\t%s : Moving and renaming converted nii files for Subject: %s\n',batchFunction, initObj.subject);
    
    niiList=moveConvertedFiles(initObj.outDir);
    % Other outputs
    dicomList = initObj.dicomList;
    outputDir = initObj.outDir;
    
    % Clear Job vars
    clearvars -except dicomList niiList outputDir
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
    initObj.dataDir = [initObj.baseDir,initObj.subject,filesep,initObj.subjectSubDir];

    % Change for naming conventions
    initObj = run_exceptions(initObj);

    % Create dicom file list
    initObj.dicomList = getDicomFileList([initObj.dataDir initObj.fileFilter]);

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
                ' ',upper(initObj.subjectSubDir)];
        end
    end
end

%% Move converted files from sub dirs to main dir and rename volumes
function [ niiFiles ] = moveConvertedFiles(outDir)
    %MOVECONVERTEDFILES Move converted files from sub dirs to main dir

    %dy1
    copyfile([outDir,filesep,'dy1/vol*'],outDir);
    %rmdir([outDir,filesep,'dy1'],'s');
    
    %dy2 rename volumes
    copyfile([outDir,filesep,'dy2/vol0000.nii'],[outDir,filesep,'vol0028.nii']);
    copyfile([outDir,filesep,'dy2/vol0001.nii'],[outDir,filesep,'vol0029.nii']);
    copyfile([outDir,filesep,'dy2/vol0002.nii'],[outDir,filesep,'vol0030.nii']);
    copyfile([outDir,filesep,'dy2/vol0003.nii'],[outDir,filesep,'vol0031.nii']);
    %rmdir([outDir,filesep,'dy2'],'s');

    %dy3 rename volumes
    copyfile([outDir,filesep,'dy3/vol0000.nii'],[outDir,filesep,'vol0032.nii']);
    copyfile([outDir,filesep,'dy3/vol0001.nii'],[outDir,filesep,'vol0033.nii']);
    copyfile([outDir,filesep,'dy3/vol0002.nii'],[outDir,filesep,'vol0034.nii']);
    %rmdir([outDir,filesep,'dy3'],'s');
    
    niiFiles=arrayfun(@(x) [x.folder,filesep,x.name],dir([outDir,filesep,'vol*.nii']),'UniformOutput',false);

end

