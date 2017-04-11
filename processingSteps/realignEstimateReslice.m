function [ motionCorrectionFileLists ] = realignEstimateReslice(params)
%function [ realignSets ] = realignEstimateReslice(niiBaseDir, realignBaseDir, subject)
%REALIGNESTIMATERESLICE Motion correction for NIfTI images
%Note correction is specific to studies of Fallypride. The function
%Excepts the following Directory structure and filename pattern:
%ANALYSIS_DIR
%  |---SUBJECT1
%        |---vol0000.nii to vol0027.nii (28 volumes corresponding to DY1)
%        |---vol0028_dc.nii to vol0031_dc.nii  (4 volumes corresponding to DY2)
%        |---vol0032_dc.nii to vol0033_dc.nii  (3 volumes corresponding to DY3)
%   Inputs:
%   niiBaseDir : Folder containing subject vol*.nii files described above
%   realignBaseDir : Folder for Motion corrected files and meanvol files
%   subject : Subject folder name 
%
%Output folder/file structure
%
%ANALYSIS_DIR
%  |---SUBJECT1
%         |---[realignBaseDir]0
%         |                 |---rvol0000.nii to rvol0027.nii
%         |                 |---rvol0028_dc.nii to rvol0031_dc.nii  
%         |                 |---rvol0032_dc.nii to rvol0033_dc.nii  
%         |                 |---meanvol0019.nii  
%         |                 |---other mat file of SPM job  
%         |
%         |---[realignBaseDir]1 (drop vol0000.nii for motion correction)
%         |                 |---rvol0001.nii to rvol0027.nii
%         |                 |---rvol0028_dc.nii to rvol0031_dc.nii  
%         |                 |---rvol0032_dc.nii to rvol0033_dc.nii  
%         |                 |---meanvol0019.nii  
%         |                 |---other mat file of SPM job  
%         |
%         |---[realignBaseDir]2 (drop vol0000.nii and vol0001.nii for motion correction)
%         |                 |---rvol0000.nii to rvol0027.nii
%         |                 |---rvol0028_dc.nii to rvol0031_dc.nii  
%         |                 |---rvol0032_dc.nii to rvol0033_dc.nii  
%         |                 |---meanvol0019.nii  
%         |                 |---other mat file of SPM job  
%         |
%
%   Outputs:
%   realignSets : Lists of nii files used for motion correction
%
%   Example:
%   realignSets = realignEstimateReslice(niiBaseDir, realignBaseDir, subject)
%   CONVERT2NII('[teba-location-analysis-dir/','analysis-set ,'DND005')
%
%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
  batchFunction='realignEstimateReslice';
  % Inputs
  subject = params.subject;
  subjectAnalysisDir = params.subjectAnalysisDir;
  logger=params.logger;
  realignBaseDir = params.realignBaseDir;
  motionCorrectionRefVol = params.motionCorrectionRefVol;
  motionCorrectionVolSetsToExclude = {{'None'} params.motionCorrectionVolSetsToExclude{:}};
  decayCorrectedFileList = params.decayCorrectedFileList;

  % Outputs
  motionCorrectionFileLists{numel(motionCorrectionVolSetsToExclude)+1} = [];
  
  logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));
  % Process spm batch for job
  
  for ii=1:numel(motionCorrectionVolSetsToExclude)
      logger.info(sprintf('Motion correction: Analysis Set %d',ii-1));

      volsToExclude = motionCorrectionVolSetsToExclude{ii};
      logger.info(sprintf('Motion correction: Excluding volumes [ %s ]',join(volsToExclude,' ')));
      
      includeIndex = cellfun(@isempty...
          ,regexp(decayCorrectedFileList,join(strcat('.*',volsToExclude,'.*'),'|')...
          ,'match'));
      realignList = decayCorrectedFileList(includeIndex);
      logger.info(sprintf('Motion correction: Setting reference volume [ %s ]',motionCorrectionRefVol));
      refIndex = find(~cellfun(@isempty, regexp(realignList,strcat('.*',motionCorrectionRefVol,'.*'),'match')));
      realignList = [realignList(refIndex) realignList];
      realignList(refIndex+1) = [];
      
      % Run current job function, passing along subject-specific inputs
      logger.info(sprintf('Motion correction: Create SPM batch job'));
      batchJob{1} = createJob(realignList);
      spm('defaults','PET');
      spm_jobman('initcfg');    
      logger.info(sprintf('Motion correction: Running SPM batch job'));
      jobOutput = spm_jobman('run', batchJob);
      % Save output (e.g., matlabbatch) for future reference
      logger.info(sprintf('Motion correction: Saving SPM batch job'));
      outName = strcat(subjectAnalysisDir,subject,'_',batchFunction,'_set_',num2str(ii-1));
      save(outName, 'batchJob');
      save([outName,'_jobOutput'], 'jobOutput');
      % Copy / rename files and move to appropriate sub-directory
      realignedDir=[subjectAnalysisDir, realignBaseDir, num2str(ii-1)];
      logger.info(sprintf('Motion correction: Copying SPM batch job output to anslysisDir %s', realignedDir));
      mkdir(realignedDir);
      copyfile([subjectAnalysisDir,'r*.*'], [realignedDir, filesep,'.']);
      delete([subjectAnalysisDir,'r*.*']);
      copyfile([subjectAnalysisDir,'mean*.*'], [realignedDir, filesep,'.']);
      delete([subjectAnalysisDir,'mean*.*']);
      copyfile([subjectAnalysisDir,'*_set_*.*'], [realignedDir, filesep,'.']);
      delete([subjectAnalysisDir,'*_set_*.*']);
      % Output
      motionCorrectionFileLists{ii} = realignList;
            
      % Clear Job vars
      clear batchJob jobOutput
      
  end

end

% % Initialize variables
% function [ initObj ] = initializeVars(niiBaseDir, subject)
%     % SPM info
%     initObj.spmDir = fileparts(which('spm'));
% 
%     % Input
%     initObj.subject = subject;
%     initObj.outDir = niiBaseDir;
%     % Directory containing the nii files
%     initObj.niiDir = strcat(niiBaseDir,initObj.subject);
% 
%     % Order of nii files for realign
%     refVolume=19;
%     volsDY1=num2cell([refVolume,0:refVolume-1,refVolume+1:27]);
%     % Non-decay corrected files
%     listDY1=cellfun(@(x) [initObj.niiDir,filesep,'vol',num2str(x,'%04d'),'.nii,1'], ...
%         volsDY1,'UniformOutput',false);
%     % Decay corrected files
%     volsDY23=num2cell([28:34]);
%     listDY23=cellfun(@(x) [initObj.niiDir,filesep,'vol',num2str(x,'%04d'),'_dc.nii,1'], ...
%         volsDY23,'UniformOutput',false);
%     % Merge file lists
%     initObj.realignList = [listDY1,listDY23]';
%     
% end 

% Create matlabbatch job
function [ matlabbatch ] = createJob(realignList)
    matlabbatch.spm.spatial.realign.estwrite.data = {realignList};
    matlabbatch.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.sep = 4;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.interp = 2;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    matlabbatch.spm.spatial.realign.estwrite.eoptions.weight = '';
    matlabbatch.spm.spatial.realign.estwrite.roptions.which = [2 1];
    matlabbatch.spm.spatial.realign.estwrite.roptions.interp = 4;
    matlabbatch.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    matlabbatch.spm.spatial.realign.estwrite.roptions.mask = 1;
    matlabbatch.spm.spatial.realign.estwrite.roptions.prefix = 'r';
  
end

