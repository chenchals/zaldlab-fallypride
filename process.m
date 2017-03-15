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
    petBet = evalin('caller','petBet');
    t1Bet = evalin('caller','t1Bet');
    analysisDir = evalin('caller','analysisDir');
    dataDir = evalin('caller','dataDir');
    pmodNiiFileExt = evalin('caller','pmodNiiFileExtension');    
    pmodAcqtimeFileExt = evalin('caller','pmodAcqtimeFileExtension');
    % For bet and co-register
    meanVol = evalin('caller','meanVol');
    meanVolThr = [meanVol '_thr'];
    coWipT1Sense = evalin('caller','coWipT1Sense');
    cerebellumT1gz = evalin('caller','cerebellumT1gz');
    putamenT1gz = evalin('caller','putamenT1gz');
    
    mriDataDir = evalin('caller','mriDataDir');
    realignDirBase = evalin('caller','realignDirBase');
    decayConstant = evalin('caller','decayConstant');
    subjects = evalin('caller','subjects');
    
    

    
    
    
    % Process current call
    callerName=getCallerName();
    scriptdir = pwd;
    addpath(scriptdir);
    if ~exist(analysisDir,'dir')
      mkdir(analysisDir)
    end
    
    % Use multicore if available
    tic;
    for ii=1:length(subjects)
        subject = subjects{ii};
        try
%             [niiList, acqTimes] = extractNiiAndAcqTimesFromPmod(dataDir, analysisDir, subject, pmodNiiFileExt, pmodAcqtimeFileExt);
%             toBacquerel=0;
%             decayCorrectNiiVolumes(niiList, acqTimes, decayConstant,toBacquerel);
%             realignEstimateReslice(analysisDir, realignDirBase,  subject);
            coregisterMeanPetWithT1(analysisDir, realignDirBase, mriDataDir, subject, t1Bet, petBet);
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
    fname=[analysisDir callerName 'log.mat'];
    save(fname, 'log');
end
function [str] = getCallerName()
  st=dbstack();
  str=st(end).name;
end