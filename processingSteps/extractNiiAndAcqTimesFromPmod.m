function [niiList, acqTimes] = extractNiiAndAcqTimesFromPmod( dataDir, outDir, subject,  pmodNiiFileExt, pmodAcqtimeFileExt )
%EXTRACTNIIFROMPMOD4D Extract nii images from PMOD merged dcm files.
%Filename pattern : SUBJECT/Decay/PMOD_Processed/SUBJECT_Sess1_all_dy.nii
%excepts the following Directory structure and filename pattern:
%DATA_DIR
%  |---SUBJECT1
%        |---Decay
%              |---PMOD_Processed
%              |     |---SUBJECT1_Sess1_all_dy.nii     
%              |     |---SUBJECT1_Sess1.acqtimes      
%   Inputs:
%   dataDir : Folder containing subject folder structure described above
%   outDir : Folder to which the output files are written. Subject folder
%            is created under this folder
%   subject : Subject folder name 
%
%   Outputs:
%   niiList   : A cell array of filenames of NIfTI files
%   acqTimes  : Parsed form PMOD SUBJECT1_Sess.acqtimes
%
%   Example:
%   [niiList, outputDir] = 
%   extractNiiFromPmod4D('[teba-location-zaldlab-fallypride]/Scan_1/','[out-folder/] ,'DND005')
%
%  Copyright 2017
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
    
    mergedPmodFile=[dataDir subject '/Decay/PMOD_Processed/' subject pmodNiiFileExt];
    acqTimesFile=[dataDir subject '/Decay/PMOD_Processed/' subject pmodAcqtimeFileExt];
    if ~exist(mergedPmodFile,'file')
        throw(MException('extractNiiAndAcqTimesFromPmod:mergedNiiFileNotFound','File %s does not exist. Use PMOD to create this file.', mergedPmodFile));
    end
    if ~exist(acqTimesFile,'file')
        throw(MException('extractNiiAndAcqTimesFromPmod:acqtimesFileNotFound','File %s does not exist. Use PMOD to create this file.', acqTimesFile));
    end
    outputDir = [outDir subject filesep];
    niiList = copyAndSplit4Dnii(mergedPmodFile, outputDir);
    fileCopy(acqTimesFile,outputDir);
    acqFileContents=importdata(acqTimesFile,'\t',2);
    acqTimes=acqFileContents.data;
end

function [ fname ] = fileCopy(fullFilePath, oDir)
    if ~exist(oDir,'dir')
        mkdir(oDir);
    end
    [~,fn,ext]=fileparts(fullFilePath);
    fname=[fn ext];
    cmd=['cp ' fullFilePath ' ' oDir fname];
    disp(cmd);
    system(cmd, '-echo');
end

%% Do fslsplit on file
function [ fList ] = copyAndSplit4Dnii(niiFileToSplit, outputDir)
    currDir = pwd;
    try
        fname = fileCopy(niiFileToSplit, outputDir);
        cd(outputDir);
        % Set fsloutputtype to NIFTI
        setenv('FSLOUTPUTTYPE','NIFTI');
        cmd =  ['fslsplit ' fname ];
        disp(cmd);
        system(cmd,'-echo');
        fList=arrayfun(@(x) [x.folder filesep x.name],dir([outputDir 'vol*.nii']),'UniformOutput',false);
    catch err
        cd(currDir);
        throw(err);
    end
    cd(currDir)
end
