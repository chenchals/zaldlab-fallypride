function [ outFiles, decayFactorDy2, decayFactorDy3 ] = decayCorrectNiiVolumes(niiFileList, acqTimes, halfLifeInMins, toBacquerel)
%DECAYCORRECTNIIVOLUMES Use decay correction for Fallypride for the nii
%                       volumes form thre DY2 and DY3 epochs. These are
%                       typically vol0028-vol0031 (4 vols, DY2) and
%                       vol0032-vol0034 (3 vols, DY3).  
%                       Writes out files with "_dc".nii. Example
%                       v0028_dc.nii.
%
% Usage:
%   decayCorrectNiiVolumes (niiFileList, acqTimes, halfLifeInMins)
%
% Inputs:
%   niiFileList    : List of vol files.  Must be exactly 35 files
%   acqTimes       : A [35x2 double]. Volume startTime and  endTime. Must
%                    be exactly 35 rows.
%   halfLifeInMins : Half-life of isotope in minutes (F18 -> 109.77)
%
% Output: 
%   decayCorrectionFactor
%
% ********************* Required ********************
% Notes to execute fslmaths from within Matlab, include the following lines
% in the startup.m file, then run startup.m or restart matlab
% >>edit startup.m
% In the Editor window check/add the following lines:
%     setenv( 'FSLDIR', '/usr/local/fsl' );
%     fsldir = getenv('FSLDIR');
%     fsldirmpath = sprintf('%s/etc/matlab',fsldir);
%     path(path, fsldirmpath);
%     %set env for path
%     setenv('PATH',[fsldir '/bin:', fsldir '/etc/fslconf:', getenv('PATH')]);
%     % Check http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslEnvironmentVariables
%     setenv('FSLOUTPUTTYPE','NIFTI');
%     clear 'fsldir' 'fsldirmpath'
% ***************************************************
%
%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
 
  batchFunction='decayCorrectNiiVolumes';
  % Set fsloutputtype to NIFTI
  setenv('FSLOUTPUTTYPE','NIFTI');
  s = regexp(niiFileList{1},'.*/(?<subject>DND\d*)/vol.*nii$','once','names');
  subject = s.subject;
  fprintf('\nProcessing for subject: %s\t%s\n',subject,batchFunction);

  % Check list length and acqTimes size
  if(length(niiFileList)~=35 || sum(size(acqTimes)==[35,2])~=2)
      error('Number of nii files in the niiFileList not 35 Or size of acqTimes is not [35 x 2]')
  end
  
  if(toBacquerel)
  % Multiply by 0.001 to counts -> mBq
     fprintf('\n\t%s: FSL Convert to mBq for subject: %s\n',batchFunction, subject);
     outFilesDy1 = multiplyNii(niiFileList(1:35),1/1000.0,'');
  else
     outFilesDy1 = niiFileList(1:28); 
  end
  
  % Decay correct DY2 Epoch files
  fprintf('\n\t%s: FSL decay correct DY2 for subject: %s\n',batchFunction, subject);
  [outFilesDy2, decayFactorDy2] = decayCorrectFiles(niiFileList(29:32),halfLifeInMins,acqTimes(29,:));
  
  % Decay correct DY3 Epoch files
  fprintf('\n\t%s: FSL decay correct DY3 for subject: %s\n',batchFunction, subject);
  [outFilesDy3, decayFactorDy3] = decayCorrectFiles(niiFileList(33:35),halfLifeInMins,acqTimes(33,:));
  
  % Check all files are written
  outFiles = {outFilesDy1{:}, outFilesDy2{:}, outFilesDy3{:}}';
  
end

%% Decay Correct file set
function [ outFiles, decayFactor ] = decayCorrectFiles(niiFileList, halfLife, startEndAcqTime)
  decayFactor =  getPetDecayCorrectionFactor(halfLife,startEndAcqTime(1),startEndAcqTime(2));
  outFiles = multiplyNii(niiFileList,decayFactor,'_dc');
end

%% Do fslmaths on files
function [outFiles ] = multiplyNii(niiFileList, factor, fileSuffix)
    for ii=length(niiFileList):-1:1
        currFile=niiFileList{ii};
        [pathS,name,ext]=fileparts(currFile);
        outFile = [pathS filesep name fileSuffix ext];
        s =  ['fslmaths -dt float ' currFile ' -mul ' num2str(factor) ' ' outFile ];
        % echo fsl cmd, output, status to matlab window.  This also ensures
        % that Matlab 'waits' for the system command to execute.
        disp(s)
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
    numer = exp(lambda*time1) * lambda * (time2 - time1);
    denom = 1 - exp(-(lambda * (time2 - time1)));
    decayCorrectionFactor = numer / denom;

end