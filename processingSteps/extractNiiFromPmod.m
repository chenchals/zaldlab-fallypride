function [niiFileList] = extractNiiFromPmod( params )
%EXTRACTNIIFROMPMOD Extract nii images from PMOD merged nii files.
%   Inputs:
%   params.subject : Subject 
%   params.subjectAnalysisDir : Subject directory for vol*.nii files 
%   params.pmodNiiFile : Full filepath of 4D nii file created using PMOD
%   params.numberOfVols : Total number of PET volumes;    
%
%   Outputs:
%   niiFileList   : A cell array of filenames of nii files
%
%   Example:
%   [niiFileList] = extractNiiFromPmod(params)
%
%  Copyright 2017
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
    batchFunction='extractNiiFromPmod';
    subject = params.subject;
    mergedPmodFile = params.pmodNiiFile;
    numberOfVols = params.numberOfVols;
    subjectAnalysisDir = params.subjectAnalysisDir;
    logger = params.logger;
    
    logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));

    if ~exist(mergedPmodFile,'file')
        msg=sprintf('File %s does not exist. Use PMOD to create this file.', mergedPmodFile);
        logger.error(msg);
        throw(MException('extractNiiFromPmod:mergedNiiFileNotFound',msg));
    end
    currDir = pwd;
    fname = filecopy(mergedPmodFile, subjectAnalysisDir);
    cd(subjectAnalysisDir);
    setenv('FSLOUTPUTTYPE','NIFTI');
    cmd =  ['fslsplit ' fname ];
    %disp(cmd);
    logger.info(cmd);
    system(cmd,'-echo');
    d=dir(subjectAnalysisDir);
    niiFileList = regexpi({d.name},'vol\d{1,}\.nii','match');
    niiFileList = [niiFileList{:}];
    niiFileList = strcat(subjectAnalysisDir,niiFileList);
    cd(currDir);
    % Check number of voldddd.nii files
    if(numel(niiFileList)~=numberOfVols )
      msg=sprintf('Number of nii files %d in niiFileList not equal to %d',...
          numel(niiFileList), numberOfVols);
      throw(MException('extractNiiFromPmod:invalidNumberOfFiles',msg));
    end

end
