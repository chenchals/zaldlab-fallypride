function [ meanMotionCorrectedVol ] = testMotionCorrectionRepeats( subject )
%TESTMOTIONCORRECTIONREPEATS Summary of this function goes here
%   Detailed explanation goes here
  %subject = 'DND005';
  maxCount = 10;
  
  baseAnalysisDir = '/Volumes/zaldlab2016/Chenchal/Apr-25-1/Fallypride/Scan-1/';
  subjectAnalysisDir = [ baseAnalysisDir  subject '/'];
  
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
  logger = Logger.getLogger([subjectAnalysisDir 'testMotionCorrection/testMotionCorrectionRepeats_log.log']);
  for ii= 1:maxCount
      params.subject=subject;
      params.subjectAnalysisDir = [baseTestDir 'repeat' num2str(ii) '/'];
      params.logger = logger;
      params.realignBaseDir = 'analysis-set';
      params.motionCorrectionRefVol = 'vol0019';
      params.motionCorrectionVolSetsToExclude = {};
      params.decayCorrectedFileListSrc = niiFileList;
      params.decayCorrectedFileList = strcat(params.subjectAnalysisDir, niiFileNames);      
      params.acqTimes = zeros(numel(niiFileList),2);
      testParams{ii} = params;     
  end
  
  for ii = 1:maxCount
      logger.info(sprintf('Doing motion correction loop %d or %d',ii,maxCount));
      params = testParams{ii};
      mkdir(params.subjectAnalysisDir);
      %cmd = ['cp 
      for jj = 1: numel(params.decayCorrectedFileListSrc)
          cmd = ['cp ' char(params.decayCorrectedFileListSrc(jj)) ' ' params.subjectAnalysisDir '.'];
          system(cmd,'-echo');
      end     
      [~, meanMotionCorrectedVol{ii},~ ] = realignEstimateReslice(params);
      [fp,fn,fe] = fileparts(char(meanMotionCorrectedVol{ii}));
      fo1 = [baseTestDir fn '_' num2str(ii) '.nii'];
      fo2 = [baseTestDir 'rp_vol0019' '_' num2str(ii) '.txt'];
      cmd = ['cp ' char(meanMotionCorrectedVol{ii}) ' ' fo1];
      system(cmd,'-echo');
      cmd = ['cp ' fp '/rp_vol0019.txt' ' ' fo2];
      system(cmd,'-echo');
      
  end

end

