function [ meanMotionCorrectedVol ] = testCoregistrationRepeats( subject )
%TESTMOTIONCORRECTIONREPEATS Summary of this function goes here
%   Detailed explanation goes here
  %subject = 'DND005';
  maxCount = 10;
  
  baseAnalysisDir = '/Volumes/zaldlab2016/Chenchal/Apr-25-1/Fallypride/Scan-1/';
  subjectAnalysisDir = [ baseAnalysisDir  subject '/'];
  subjectMriDataDir =['/Volumes/zaldlab/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/' subject '/T1_2_MNI/'];
  t1File = [subjectMriDataDir 'coWIPT1W3DTFESENSEs002a001.nii'];
  t1Bet = [0 0.4];
  roiFiles = strcat(subjectMriDataDir,{
      'cerebellum_T1space.nii.gz'
      'putamen_T1space.nii.gz'
      });
  roiThresholds = [1 0.99];
  meanVolFile = 'meanvol0019.nii';
  meanPetVolThreshold = 1; 
  petBet = [0 0.4];
  
  %Get list of nii files to be used for motion correction
  d = dir([subjectAnalysisDir,'vol*.nii']);
  nonDcFileIndex = find(~cellfun(@isempty,regexp({d.name},'vol00((0|1)[0-9])|(2[0-7]).nii','match')));
  dcFileIndex = find(~cellfun(@isempty,regexp({d.name},'.*_dc.nii','match')));
  niiFileNames = {d([nonDcFileIndex dcFileIndex]).name};
  niiFileList = strcat(d(1).folder,'/', niiFileNames);
  %create test params array
  testParams = {maxCount};
  baseTestDir = [subjectAnalysisDir 'testMotionCorrection/'];
  mkdir(baseTestDir);
  logger = Logger.getLogger([subjectAnalysisDir 'testMotionCorrection/testCoregistrationRepeats_log.log']);
  for ii= 1:maxCount     
      params.subject=subject;
      params.subjectAnalysisDir = [baseTestDir 'repeat' num2str(ii) '/'];
      params.logger = logger;      
      params.t1File = t1File;
      params.t1Bet = t1Bet;
      params.roiFiles = roiFiles;
      params.roiThresholds = roiThresholds;      
      params.meanMotionCorrectedVols = {[params.subjectAnalysisDir 'analysis-set0/' meanVolFile]};
      params.meanPetVolThreshold = meanPetVolThreshold;
      params.petBet = petBet;      
      testParams{ii} = params;     
  end
  
  parfor ii = 2:maxCount
      logger.info(sprintf('Doing motion correction loop %d or %d',ii,maxCount));
      params = testParams{ii};
      mkdir(params.subjectAnalysisDir);   
      coregisterMeanPetWithT1(params);      
  end

end

