function process()
% Creates preprocessed analysis output directory structure (created if not exist)
%   [analysisDir]
%   [analysisDir]/subject : For converted files
%   [analysisDir]/[subject]/[realignDirBase]0
%   [analysisDir]/[subject]/[realignDirBase]1 vol0000.nii dropped
%   [analysisDir]/[subject]/[realignDirBase]2 vol0000.nii and vol0002.nii dropped
%
%
% Gather all variables from the caller
    params.analysisDir = evalin('caller','analysisDir');
    params.realignBaseDir = evalin('caller','realignDirBase');
    params.dataDir = evalin('caller','dataDir');
    params.pmodNiiFileExt = evalin('caller','pmodNiiFileExtension');    
    params.pmodAcqtimeFileExt = evalin('caller','pmodAcqtimeFileExtension');
    params.decayConstant = evalin('caller','decayConstant');
    % For bet and co-register
    params.mriDataDir = evalin('caller','mriDataDir');
    params.petBet = evalin('caller','petBet');
    params.t1Bet = evalin('caller','t1Bet');
    params.meanVol = evalin('caller','meanVol');
    params.meanVolThr = [params.meanVol '_thr'];
    params.coWipT1Sense = evalin('caller','coWipT1Sense');
    params.cerebellumT1gz = evalin('caller','cerebellumT1gz');
    params.putamenT1gz = evalin('caller','putamenT1gz');
    params.toBacquerel=0;
    params.callerName=getCallerName();    
    subjects = evalin('caller','subjects');

     % Process current call
    scriptdir = pwd;
    addpath(scriptdir);
    if ~exist(params.analysisDir,'dir')
      mkdir(params.analysisDir)
    end
    startDiary([params.analysisDir filesep params.callerName '_diary.txt']);
    
    % Use multicore if available
    tic;
    parfor ii=1:length(subjects)
        subject = subjects{ii};
        try
            [niiList, acqTimes] = extractNiiAndAcqTimesFromPmod(subject,params);
            decayCorrectNiiVolumes(niiList, acqTimes, params.decayConstant,params.toBacquerel);
            realignEstimateReslice(subject, params);
            coregisterMeanPetWithT1(subject, params);
            log(ii).message = [subject,' :: ','Preprocess successful'];
        catch err % on error collect log
            log(ii).message = [subject,' :: ***Preprocess FAILED ***', err.identifier,'::',err.message];
            log(ii).stack = char(join(cellfun(@(f,n,l) ...
                ['file: ',f(max(strfind(f,'/'))+1:end),' -function: ',n,' -line:',num2str(l)]...
                , {err.stack.file}', {err.stack.name}' ,{err.stack.line}','UniformOutput',false)...
                ,' ; '));
            cd(scriptdir);
            continue;
        end % end try/catch
    end % end parfor
    t=toc;
    
    disp('***Processing Summary****')
    for ii=1:length(log)
        disp('*********************************')
        disp(log(ii))
    end
    fprintf('Time to preProcess %d Subjects: %.3g seconds\n', ...
        length(subjects), t);
    fname=[params.analysisDir filesep params.callerName 'log.mat'];
    save(fname, 'log');
    diary('off');
end
function startDiary(fname)
    if strmatch(get(0,'Diary'),'on')
        diary('off');
    end
    diary(fname);
    diary('on');
end
function [str] = getCallerName()
  st=dbstack();
  str=st(end).name;
end