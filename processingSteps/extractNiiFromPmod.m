function [niiList] = extractNiiFromPmod( params )
%EXTRACTNIIFROMPMOD Extract nii images from PMOD merged nii files.
%   Inputs:
%   params.analysisDir : Folder containing subject folder structure described above
%   params.subject : Subject folder name 
%   params.pmodNiiFile : Full filepath of 4D nii file created using PMOD
%
%   Outputs:
%   niiList   : A cell array of filenames of NIfTI files
%
%   Example:
%   [niiList] = extractNiiFromPmod(params)
%
%  Copyright 2017
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
    batchFunction='extractNiiFromPmod';
    subject = params.subject;
    logger=params.logger;
    logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));
    outputDir = [params.analysisDir subject filesep];
    mergedPmodFile = params.pmodNiiFile;
    if ~exist(mergedPmodFile,'file')
        msg=sprintf('File %s does not exist. Use PMOD to create this file.', mergedPmodFile);
        logger.error(msg);
        throw(MException('extractNiiAndAcqTimesFromPmod:mergedNiiFileNotFound',msg));
    end
    currDir = pwd;
    fname = filecopy(mergedPmodFile, outputDir);
    cd(outputDir);
    setenv('FSLOUTPUTTYPE','NIFTI');
    cmd =  ['fslsplit ' fname ];
    %disp(cmd);
    logger.info(cmd);
    system(cmd,'-echo');
    %niiList = arrayfun(@(x) [x.folder filesep x.name],dir([outputDir 'vol*.nii']),'UniformOutput',false);
    d=dir([outputDir 'vol*.nii']);
    niiList = strcat(outputDir,{d.name});
    cd(currDir);

end
