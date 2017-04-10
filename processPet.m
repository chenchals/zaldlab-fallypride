function processPet()
% Creates preprocessed analysis output directory structure (created if not exist)
%   [analysisDir]
%   [analysisDir]/subject : For converted files
%   [analysisDir]/[subject]/[realignDirBase]0
%   [analysisDir]/[subject]/[realignDirBase]1 vol0000.nii dropped
%   [analysisDir]/[subject]/[realignDirBase]2 vol0000.nii and vol0002.nii dropped
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
  subjects=evalin('caller','subjects');
  params=evalin('caller','default_params()');
  subjectParams={numel(subjects)};
  subjectErrors={numel(subjects)};
  for subInd=1:numel(subjects)
      subject=subjects{subInd};
      disp(['Validating files for Subject: ' subject])
      override=[];
      try
          override=evalin('caller',subject);
      catch 
          %continue
      end
      override.subject=subject;
      [subjectParams{subInd}, subjectErrors{subInd}]=validate(parseArgs(params,override));
  end
  % Process current call
  scriptdir = pwd;
  addpath(scriptdir);
  addpath([scriptdir filesep 'processingSteps']);
  
  % Use multicore if available
  tic;
  parfor ii=1:length(subjectParams)
      params = subjectParams{ii};
      subject = params.subject;
      params.subjectAnalysisDir=[params.analysisDir subject filesep];
      paramsFile = [params.subjectAnalysisDir subject '_params.mat'];
      if ~exist(params.subjectAnalysisDir,'dir')
          mkdir(params.subjectAnalysisDir)
%        elseif previousRunSuccessful(paramsFile)
%            continue;
      end
      params = updateAndSave(params,'paramsFile',  paramsFile);
      % Create logger
      params = addLogger(params);
      logger = params.logger;
      validationErrors = subjectErrors{ii};
      if numel(validationErrors.errors)>0
          msg=strjoin(validationErrors.errors,'\n');
          processingFailed(params,MException('processPet:validationErrors',msg));
          cd(scriptdir);
          continue;
      end
      try
          [niiFileList] = extractNiiFromPmod(params);
          params = updateAndSave(params,'niiFileList',  niiFileList);
          [acqTimes] = extractAcqTimesFromPmod(params);
          params = updateAndSave(params,'acqTimes',  acqTimes);
          [params.decayCorrectedFileList, params.deacyCorrectionFactor] = decayCorrectNiiVolumes(params);
          params = saveParams(params);
          %realignEstimateReslice(subject, params);
          %coregisterMeanPetWithT1(subject, params);
          processingSuccessful(params);
          cd(scriptdir);
      catch err % on error collect log
          processingFailed(params,err);
          cd(scriptdir);
          continue;
      end % end try/catch
  end % end parfor
  disp(toc)
end

%%
function [ params ] = addLogger(params)
  params.logFile = [params.subjectAnalysisDir params.subject '_petProcess.log'];
  logger = Logger.getLogger(params.logFile);
  params = updateAndSave(params, 'logger', logger);
end

%%
function params = updateAndSave(params,field,value)
   params.(field)=value;
   save(params.paramsFile,'params');
end

function params = saveParams(params)
   save(params.paramsFile,'params');
end
%%
function [] = processingSuccessful(params)
   params.logger.info([ params.subject ' :: Processing Successful']);
   params.logger.info('********************************************');
   params.exception=[];
   updateAndSave(params,'isProcessingSuccessful',true);   
end

%%
function [] = processingFailed(params,exObj)
   params.logger.error(['*********' params.subject ' :: Processing Failed']);
   params.logger.error(exObj);
   params.logger.error('********************************************');
   params.exception=exObj;
   updateAndSave(params,'isProcessingSuccessful',false);
   %cleanup(params);
end

%% Cleanup all results for subject
function [] = cleanup(params)
   %cleanup
   outputDir = [params.analysisDir params.subject filesep];
   cmds = {
       ['rm -rf ' outputDir '*.nii*']
       ['rm -rf ' outputDir '*.acqtimes*']
       ['rm -rf ' outputDir params.realignBaseDir '*']
       };
   cellfun(@(x) system(x, '-echo'),cmds);

end

%%
function [ paramOpts, subjectErr ] = validate(paramOpts)
  subj=paramOpts.subject;
  subjDir=[paramOpts.dataDir subj filesep paramOpts.pmodAnalysisDir filesep];  
  mniDir=[paramOpts.mriDataDir subj filesep paramOpts.mniBaseDir filesep];
  fList={ 
        strcat(subjDir, subj, paramOpts.pmodNiiFileExt)
        strcat(subjDir, subj, paramOpts.pmodAcqtimeFileExt)
        strcat(mniDir, paramOpts.coWipT1Sense)
      };
  fListRois=strcat(mniDir,paramOpts.brainT1Rois);
  fList=vertcat({fList{:} fListRois{:}})';

  subjectErr.subject=subj;
  subjectErr.errors={};
  for ii=1:numel(fList)
    if ~exist(fList{ii},'file')
      subjectErr.errors{end+1,1}=sprintf('**%s*** File does not exist %s', subj, fList{ii});
    end
  end
  %absolute file paths
  paramOpts.pmodNiiFile=char(fList{1});
  paramOpts.acqTimesFile=char(fList{2});
  paramOpts.t1File=char(fList{3});
  paramOpts.roiFiles=fListRois;
  
end

%%
function [ success ] = previousRunSuccessful(paramsFile)
  success = 0;
  if exist(paramsFile, 'file')
    prevRun = load(paramsFile,'-mat');
     if isfield(prevRun,'params') && isfield(prevRun.params,'isProcessingSuccessful')
       success = prevRun.params.isProcessingSuccessful;
     end
  end
end