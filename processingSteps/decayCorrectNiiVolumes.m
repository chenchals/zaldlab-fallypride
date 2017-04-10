function [ decayCorrectedFileList, decayCorrectionFactors ] = decayCorrectNiiVolumes(params)
%DECAYCORRECTNIIVOLUMES Decay correction for volumnes acquired with delays.
%   For Fallypride typically DY1, DY2, and DY3 epochs. DY2 starts at
%   vol0029 and DY3 at vol0032
%
%   Inputs:
%   params.analysisDir : Folder containing subject folder structure described above
%   params.subject : Subject folder name 
%   params.pmodNiiFile : Full filepath of 4D nii file created using PMOD
%
%   params.subject : Subject Id
%   params.subjectAnalysisDir : Subject directory containing vol*.nii files 
%   params.numberOfVols : Total number of PET volumes;    
%   params.pmodAcqtimeFileExt : PMOD acquisition times file.  Must contain
%          params.numberOfVols of rows for start and end time of slices in each volume
%   params.countsToBacquerel : (true|false) Convert PET Counts to Bq correction flag;
%   params.doDecayCorrection : (true|false) Decay correction for PET scans done at Gaps DY2, DY3..;
%   params.decayConstant : Decay constant in minutes (109.77 Fallypride) 
%   params.decayCorrectionFileSuffix : _dc -  Include only tdecay correction is needed
%    
%   params.decayCorrectionVolLists : List of nii volumes to apply decay
%          correction Zero-based. Example for Fallypride
%          {
%           {'vol0028' 'vol0029' 'vol0030' 'vol0031'}  % DY2
%           {'vol0032' 'vol0033' 'vol0034'}            % DY3
%          };
%   Outputs:
%   decayCorrectedFileList : A cell array of all subject filenames with decay
%            corrected files
%   decayCorrectionFactors : The multiplication factors used for different
%   epochs for decay correction
%  Copyright 2017
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
 
  batchFunction='decayCorrectNiiVolumes';
  subject = params.subject;
  logger=params.logger;
  logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));

  % Set fsloutputtype to NIFTI
  setenv('FSLOUTPUTTYPE','NIFTI');
  decayCorrectedFileList = params.niiFileList;
  acqTimes = params.acqTimes;
  numberOfVols = params.numberOfVols;
  toBacquerel = params.countsToBacquerel;
  doDecayCorrection = params.doDecayCorrection;
  
  % Check list length and acqTimes size
  if(numel(params.niiFileList)~=numberOfVols || numel(acqTimes)~=(numberOfVols*2))
      msg=sprintf('Number of nii files %d in niiFileList not equal to %d Or size of acqTimes is not [%d x 2]',...
          numel(niiFileList), numberOfVols, numberOfVols);
      throw(MException('decayCorrectNiiVolumes:invalidNumberOfFiles',msg));
  end
  
  if(toBacquerel)
      logger.info(sprintf('FSL conversion from counts to mBq for subject %s',subject));
      multiplyNii(decayCorrectedFileList,1/1000.0,'')
  end
  decayCorrectionFactors(numel(params.decayCorrectionVolLists)) = 0;
  if(doDecayCorrection)
      logger.info(sprintf('FSL Decay Correction for subject %s',subject));
      for i=1:numel(params.decayCorrectionVolLists)
          dcList = params.decayCorrectionVolLists(i);
          startEndAcqTimeIndex = regexp(dcList{:}{1},'(\d{1,})$','tokens');
          startEndAcqTimeIndex = str2double(char(startEndAcqTimeIndex{1})) + 1;%29 for DY2
          dcList = strcat(params.subjectAnalysisDir, dcList{:},'.nii');
          [dcFiles, decayCorrectionFactors(i)] = decayCorrectFiles(dcList,params.decayConstant,acqTimes(startEndAcqTimeIndex,:),params.decayCorrectionFileSuffix);
          decayCorrectedFileList = regexprep(decayCorrectedFileList,dcList,dcFiles);
          clearvars dcList startEndAcqTimeIndex dcFiles;
      end
  end
    
end

%% Decay Correct file set
function [ outFiles, decayFactor ] = decayCorrectFiles(niiFileList, halfLife, startEndAcqTime, decayCorrectSuffix)
  params = evalin('caller','params');
  decayFactor =  getPetDecayCorrectionFactor(halfLife,startEndAcqTime(1),startEndAcqTime(2));
  outFiles = multiplyNii(niiFileList,decayFactor,decayCorrectSuffix);
end

%% Do fslmaths on files
function [outFiles ] = multiplyNii(niiFileList, factor, fileSuffix)
    logger = evalin('caller','params.logger');
    for ii = length(niiFileList):-1:1
        currFile = niiFileList{ii};
        [pathS,name,ext] = fileparts(currFile);
        outFile = [pathS filesep name fileSuffix ext];
        s =  ['fslmaths -dt float ' currFile ' -mul ' num2str(factor) ' ' outFile ];
        % echo fsl cmd, output, status to matlab window.  This also ensures
        % that Matlab 'waits' for the system command to execute.
        logger.info(s)
        system(s,'-echo');
        outFiles(ii) = {outFile};
    end
end

%% Compute decay correction factor
function [ decayCorrectionFactor ] = getPetDecayCorrectionFactor( halfLife, time1, time2 )
%GETPETDECAYCORRECTIONFACTOR Decay correction factor for PET images
% Source: http://www.turkupetcentre.net/petanalysis/decay.html
%
% Usage:
%   factor = getPetDeacyCorrectionFactor (109.77, 5280, 6030)
%
% Inputs:
%   halfLife : Half-life of isotope in minutes (F18 -> 109.77)
%   time1    : Slice begin time secs (for DND040, DY2-> 5280, DY3-> 9367)
%   time2    : Slice end time secs (for DND040, DY2-> 6030, DY3-> 10567)
%
% Output: 
%   decayCorrectionFactor
%
%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
    halfLifeSecs = halfLife*60;
    lambda = log(2)/halfLifeSecs;
    %numer = exp(time1.*lambda) * lambda .* (time2 - time1);
    numer = exp(lambda*time1) * lambda * (time2 - time1);
    denom = 1 - exp(-(lambda * (time2 - time1)));
    decayCorrectionFactor = numer / denom;

end