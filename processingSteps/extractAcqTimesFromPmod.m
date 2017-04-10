function [ acqTimes ] = extractAcqTimesFromPmod( params )
%EXTRACTACQTIMESFROMPMOD4D Extract nii images from PMOD merged dcm files.
%Filename pattern : SUBJECT/Decay/PMOD_Processed/SUBJECT1_Sess1.acqtimes
%   Inputs:
%   params.analysisDir : Folder containing subject folder structure described above
%   params.subject : Subject folder name 
%   params.pmodAcqTimesFile : Full filepath of acquisition times file created using PMOD
%
%   Outputs:
%   acqTimes   : An [nVols x 2 double] array
%
%   Example:
%   [ acqTimes ] = extractAcqTimesFromPmod(params)
%
%  Copyright 2017
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
   batchFunction='extractAcqTimesFromPmod';
   subject = params.subject;
   logger=params.logger;
   logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));
   %Parameters
    outputDir = [params.analysisDir subject filesep];
    acqTimesFile = params.acqTimesFile;
    if ~exist(acqTimesFile,'file')
        msg=sprintf('File %s does not exist. Use PMOD to create this file.', acqTimesFile);
        logger.error(msg);
        throw(MException('extractAcqTimesFromPmod:acqtimesFileNotFound',msg));
    end     
    fname = filecopy(acqTimesFile, outputDir);
    currDir = pwd;
    cd(outputDir);
    acqFileContents=importdata(fname,'\t',2);
    acqTimes=acqFileContents.data;
    cd(currDir);
end
