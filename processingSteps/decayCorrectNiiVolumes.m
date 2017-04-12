function [ decayCorrectedFileList, decayCorrectionFactors ] = decayCorrectNiiVolumes(params)
%DECAYCORRECTNIIVOLUMES Decay correction for volumnes acquired with delays.
%   For Fallypride typically DY1, DY2, and DY3 epochs. DY2 starts at
%   vol0029 and DY3 at vol0032
%
%   Inputs:
%   params.subject : Subject Id
%   params.subjectAnalysisDir : Subject directory containing vol*.nii files 
%   params.logger : Logger for logging progress 
%   params.niiFileList : Full filepath of nii files fro this function
%   params.numberOfVols : Total number of PET volumes;    
%   params.countsToBacquerel : (true|false) Convert PET Counts to Bq correction flag;
%   params.doDecayCorrection : (true|false) Decay correction for PET scans done at Gaps DY2, DY3..;
%   params.decayConstant : Decay constant in minutes (109.77 Fallypride) 
%   params.decayCorrectionFileSuffix : _dc -  Include only tdecay correction is needed   
%   params.acqTimes : Acquisition times. Array [params.numberOfVols, 2]
%           The start and end time of slices for each volume
%   params.decayCorrectionVolSets : List of nii volumes to apply decay
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
  % Set fsloutputtype to NIFTI
  setenv('FSLOUTPUTTYPE','NIFTI');
  % Inputs
  subject = params.subject;
  subjectAnalysisDir = params.subjectAnalysisDir;
  logger=params.logger;
  niiFileList = params.niiFileList;
  numberOfVols = params.numberOfVols;
  toBacquerel = params.countsToBacquerel;
  doDecayCorrection = params.doDecayCorrection;
  decayConstant = params.decayConstant;
  decayCorrectionFileSuffix = params.decayCorrectionFileSuffix;
  acqTimes = params.acqTimes;
  decayCorrectionVolSets = params.decayCorrectionVolSets;
  % Outputs
  decayCorrectedFileList = niiFileList;
  decayCorrectionFactors = [];
  
  logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));
  % Check list length and acqTimes size
  if(numel(niiFileList)~=numberOfVols || numel(acqTimes)~=(numberOfVols*2))
      msg=sprintf('Number of nii files %d in niiFileList not equal to %d Or size of acqTimes is not [%d x 2]',...
          numel(niiFileList), numberOfVols, numberOfVols);
      throw(MException('decayCorrectNiiVolumes:invalidNumberOfFiles',msg));
  end
  
  if(toBacquerel)
      logger.info(sprintf('FSL conversion from counts to mBq for subject %s',subject));
      %multiplyNii(decayCorrectedFileList,1/1000.0,'');
      multiplyCmds = multiplyNii(decayCorrectedFileList,1/1000.0,'');
      for ii=1:numel(multiplyCmds)
          cmdStr = multiplyCmds{ii};
          logger.info(cmdStr);
          system(cmdStr,'-echo');
      end
  else
      logger.info(sprintf('FSL **NO conversion from counts to mBq** for subject %s',subject));
  end
  
  if(doDecayCorrection && numel([decayCorrectionVolSets{:}]))
      logger.info(sprintf('FSL Decay Correction for subject %s',subject));
      decayCorrectionFactors(numel(decayCorrectionVolSets)) = 1;
      for dc=1:numel(decayCorrectionVolSets)
          dcList = decayCorrectionVolSets{dc};
          startEndAcqTimeIndex = regexp(dcList{1},'(\d{1,})$','tokens');
          startEndAcqTimeIndex = str2double(char(startEndAcqTimeIndex{1})) + 1;%29 for DY2
          dcList = strcat(subjectAnalysisDir, dcList,'.nii');
          decayCorrectionFactors(dc) = getPetDecayCorrectionFactor(decayConstant,acqTimes(startEndAcqTimeIndex,:));
          [multiplyCmds, dcFiles ] = multiplyNii(dcList, decayCorrectionFactors(dc), decayCorrectionFileSuffix);
          for ii=1:numel(multiplyCmds)
              cmdStr = multiplyCmds{ii};
              logger.info(cmdStr);
              system(cmdStr,'-echo');
          end
          decayCorrectedFileList = regexprep(decayCorrectedFileList,dcList,dcFiles);
          clearvars dcList startEndAcqTimeIndex dcFiles;
      end
  else
      logger.info(sprintf('FSL **NO Decay Correction** for subject %s',subject));
  end
    
end

%% Do fslmaths on files
function [multiplyCmds, oFiles ] = multiplyNii(niiFileList, factor, fileSuffix)
    for ii = length(niiFileList):-1:1
        currFile = niiFileList{ii};
        [pathS,name,ext] = fileparts(currFile);
        oFile = [pathS filesep name fileSuffix ext];
        multiplyCmds{ii} =  ['fslmaths -dt float ' currFile ' -mul ' num2str(factor) ' ' oFile ];
        oFiles{ii} = oFile;
    end
end

%% Compute decay correction factor
function [ decayCorrectionFactor ] = getPetDecayCorrectionFactor( halfLife, startEndTimes )
%GETPETDECAYCORRECTIONFACTOR Decay correction factor for PET images
% Source: http://www.turkupetcentre.net/petanalysis/decay.html
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
    time1 = startEndTimes(1);
    time2 = startEndTimes(2);
    halfLifeSecs = halfLife*60;
    lambda = log(2)/halfLifeSecs;
    numer = exp(lambda*time1) * lambda * (time2 - time1);
    denom = 1 - exp(-(lambda * (time2 - time1)));
    decayCorrectionFactor = numer / denom;

end