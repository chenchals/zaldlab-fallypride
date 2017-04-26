function coregisterMeanPetWithT1( params )
%COREGISTERMEANPETWITHT1 Coregister the mean PET scan with subject T1 Scan
%
%   
    batchFunction='coregisterMeanPetWithT1';
    % Set fsl output to nii
    setenv('FSLOUTPUTTYPE','NIFTI');

    % Inputs
    subject = params.subject;
    subjectAnalysisDir = params.subjectAnalysisDir;
    
    t1File = params.t1File;
    t1BetFvals = params.t1Bet;
    roiFiles = params.roiFiles;
    roiThresholds = params.roiThresholds;
    
    meanMotionCorrectedVols = params.meanMotionCorrectedVols;
    petBetFvals = params.petBet; 
    
    logger = params.logger;
    logger.info(sprintf('Processing for subject: %s\t%s',subject,batchFunction));
   
    % keep track of the where this function is
    currentDir = pwd;
    
    % BET T1 scan into subjetAnalysisDir/tmp 
    subjectTempDir = [subjectAnalysisDir 'temp/'];
    logger.info(sprintf('Preparing temp T1 BET for subject: %s in dir: %s',subject,subjectTempDir));
    createDir(subjectTempDir);
    tmpT1File =strcat(subjectTempDir, filecopy(t1File, subjectTempDir));
    [ betCmds, t1BetFilenames ] = createFslBetCmds(tmpT1File, t1BetFvals);  
    for ii = 1:numel(betCmds)
        logger.info(betCmds{ii});
        system(betCmds{ii});
    end
    roiFilenames = filecopy(roiFiles,subjectTempDir);
    
    % Call fsl functions for each realigned set
    for ii = 1:numel(meanMotionCorrectedVols)
        threshold = 1;
        meanVol = meanMotionCorrectedVols{ii};
        meanVolThr = regexprep(meanVol,'.nii','_thr.nii');
        petDir = [fileparts(meanVol) filesep];
        logger.info(sprintf('Processing for subject: %s analysis dir:%s', subject, petDir));
        logger.info(sprintf('Preparing filesets for subject: %s to coregister',subject));
        % Copy T1 BET from temp
        cmdStr = ['cp ' subjectTempDir '* ' petDir];
        logger.info(sprintf('Copy T1 BET, ROI files for subject: %s to coregister',subject));
        logger.info(cmdStr);
        system(cmdStr, '-echo');
        % Threshold mean PET
        cmdStr = ['fslmaths ',meanVol,' -thr ', num2str(threshold),' ', meanVolThr];
        logger.info(sprintf('Threshold mean PET file for subject: %s to coregister',subject));
        logger.info(cmdStr)
        system(cmdStr, '-echo');
        % BET mean thresholded PET to petDir
        logger.info(sprintf('BET mean thresholded PET file for subject: %s to coregister',subject));
        [ betCmds, petBetFilenames ] = createFslBetCmds(meanVolThr, petBetFvals);
        for jj = 1:numel(betCmds)
            logger.info(betCmds{jj});
            system(betCmds{jj});
        end
        % Run coregistration, transfer ROI and threshold for each T1 BET with each PET BET for each ROI        
        for t1Bet = 1:numel(t1BetFilenames)
            t1Fname = t1BetFilenames{t1Bet};
            t1BetSuffix = strcat('_T1',char(regexp(t1Fname,'f\d?\.?\d+','match')));            
            t1File = strcat(petDir,t1Fname);
            % for each BET'd mean thresholded PET scans
            for petBet = 1:numel(petBetFilenames)
                petFname = petBetFilenames{petBet};
                petBetSuffix = strcat('_PET',char(regexp(petFname,'f\d?\.?\d+','match')));
                petFile = strcat(petDir,petFname);
                % Do for each ROI
                for roi = 1:numel(roiFilenames)
                    roiThresholdValue = num2str(roiThresholds(roi));
                    roiFname = roiFilenames{roi};
                    roiName = regexprep(roiFname,'_T1.*$','');
                    roiFile = strcat(petDir,roiFname);
                    % Output files
                    T1_2_meanVol = strcat(petDir,'T1_2_meanvol',t1BetSuffix,petBetSuffix);
                    T1_2_meanVolMat =strcat(T1_2_meanVol,'.mat');
                    meanVol_2_T1 = strcat(petDir,'meanvol_2_T1',t1BetSuffix,petBetSuffix);
                    roiInPETSpaceFname = strcat(roiName,'_in_PET_Space',t1BetSuffix,petBetSuffix);
                    roiInPETSpace = strcat(petDir,roiInPETSpaceFname);
                    roiInPETSpaceThr = strcat(roiInPETSpace,'_thr');
                    %Co-register
                    cmdStr = ['flirt -in ', t1File, ' -ref ', petFile, ' -dof 6 -out ', T1_2_meanVol, ' -omat ', T1_2_meanVolMat];
                    logger.info(sprintf('Coregister for subject: %s T1: %s to PET: %s',subject,t1Fname,petFname));
                    logger.info(cmdStr);
                    system(cmdStr,'-echo');
                    % Create inverse transform matrix
                    cmdStr = ['convert_xfm -omat ', meanVol_2_T1, '.mat', ' -inverse ', T1_2_meanVolMat];
                    logger.info(cmdStr);
                    system(cmdStr,'-echo'); 
                    % Move ROI from T1 to PET space
                    cmdStr = ['flirt -in ', roiFile, ' -ref ', petFile, ' -applyxfm -init ', T1_2_meanVolMat, ' -out ', roiInPETSpace];
                    logger.info(sprintf('Move %s from T1 space: %s to PET space: %s for subject: %s',roiName,roiFname,petFname,subject));
                    logger.info(cmdStr);
                    system(cmdStr,'-echo');
                    % Threshold ROI in PET space
                    cmdStr = ['fslmaths ',roiInPETSpace,' -thr ', roiThresholdValue,' ', roiInPETSpaceThr];
                    logger.info(sprintf('Threshold ROI in PET space: %s for subject: %s',roiInPETSpaceFname,subject));
                    logger.info(cmdStr);
                    system(cmdStr,'-echo');                    
                    
                end
            end
         end
     end
  
    cd(currentDir); % change back to the directory fo this file
end

% %% Compute coregister steps for each BET
% function processCoregistration(analysisDir, petBetFval, t1BetFval, coWipT1SenseFile, meanVolThr, cerebellumT1gz, putamenT1gz)
%     t1PetBetSuffix = '';
%     petBetSuffix = '';
%     % change filenames for bet
%     if(petBetFval>0)
%         t1PetBetSuffix = regexprep(['_bet_','T1f',num2str(t1BetFval),'_','PETf',num2str(petBetFval)],'\.','');
%         petBetSuffix = regexprep(['_bet_','PETf',num2str(petBetFval)],'\.','');
%     end
%     meanVolThrBet =[meanVolThr, petBetSuffix];
%     % For coregister
%     coWipT1SenseBet = coWipT1SenseFile;
%     T1_2_meanVolBet = ['T1_2_meanvol', t1PetBetSuffix];
%     meanVol_2_T1Bet = ['meanvol_2_T1', t1PetBetSuffix];
%     % Cerebellum PET space for subject
%     cerebellumInPetSpaceBet = ['cerebellum_in_PETspace', t1PetBetSuffix];
%     % Putamen PET space for subject
%     putamenInPetSpaceBet = ['putamen_in_PETspace', t1PetBetSuffix];
% 
%     % Extract Brain (remove skull)
%     if(petBetFval>0)
%         fprintf('\n\t\t Removing skull through FSL-BET with a -f =%s for analysis dir %s\n',num2str(petBetFval), analysisDir);
%         % cmd bet inF oF  -f 0.5 -g 0  (output use thr_brain_bet_f05)
%         % bet mean Thr vol
%         createFslBetCmds(meanVolThr, meanVolThrBet, petBetFval);
%     else
%         fprintf('\n\t\t Without FSL-BET for analysis dir %s\n',analysisDir);
%     end
% 
%     % Coregister T1 to PET
%     fslCoregister(coWipT1SenseBet, meanVolThrBet, T1_2_meanVolBet, meanVol_2_T1Bet);
% 
%     % Move cerebellum T1 to PET space
%     fslMoveRoiFromT1ToPet(cerebellumT1gz, meanVolThrBet, T1_2_meanVolBet, cerebellumInPetSpaceBet);
%     fslThresholdVolume(cerebellumInPetSpaceBet, [cerebellumInPetSpaceBet,'_thr'], 1);
% 
%     % Move putamen T1 to PET space
%     fslMoveRoiFromT1ToPet(putamenT1gz, meanVolThrBet, T1_2_meanVolBet, putamenInPetSpaceBet);
%     fslThresholdVolume(putamenInPetSpaceBet, [putamenInPetSpaceBet,'_thr'],0.99);
% end


% %% Threshold PET mean volume
% function fslThresholdVolume(volFile, volThrFile, thresholdValue)
%     % Threshold the mean volume
%     cmdStr = ['fslmaths ',volFile,' -thr ', num2str(thresholdValue),' ', volThrFile];
%     callSystem(cmdStr);
% end
% 
% %% Coregister T1 to PET
% function fslCoregister(coWipT1SenseFile, meanVolThrFile, t1ToMeanVolFile, meanVolToT1File)
%     % coregister
%     cmdStr = ['flirt -in ', coWipT1SenseFile, ' -ref ', meanVolThrFile, ' -dof 6 -out ', t1ToMeanVolFile, ' -omat ', t1ToMeanVolFile, '.mat'];
%     callSystem(cmdStr);
%     % Create inverse xFrom matrix
%     invCmdStr = ['convert_xfm -omat ', meanVolToT1File, '.mat', ' -inverse ', t1ToMeanVolFile, '.mat'];
%     callSystem(invCmdStr);
% end
% 
% %% Move ROI from T1 to PET space
% function fslMoveRoiFromT1ToPet(roiT1File, meanVolThrFile, t1ToMeanVolMatFile, roiPetFile)
%     % Threshold the mean volume
%     cmdStr = ['flirt -in ', roiT1File, ' -ref ', meanVolThrFile, ' -applyxfm -init ', t1ToMeanVolMatFile, '.mat', ' -out ', roiPetFile];
%     callSystem(cmdStr);
% end

%%
function [ cmdLines, oFilenames ] = createFslBetCmds(inFile, fvals)
    % FSL bet for brain extraction
    cmdLines{numel(fvals)}=[];
    oFilenames{numel(fvals)}=[];
    inFile = char(inFile);
    [fp,fn,~] = fileparts(inFile);
    for ii =1:numel(fvals)
        fvalStr = num2str(fvals(ii));
        oFile = [fn,'_bet_f',fvalStr,'.nii'];
        oFilenames{ii} = oFile;
        cmdLines{ii} = ['bet ', inFile, ' ', fp, filesep, oFile, ' -f ', fvalStr, ' -g 0'];
    end
end

function [] = createDir(dirName)
    if exist(dirName,'dir')
        rmdir(dirName,'s');
    end
    mkdir(dirName);
end

% 
% %%
% function callSystem(cmdLine)
%     % Execute the commands on system OS
%     disp(cmdLine)
%     system(cmdLine);
% end
% 
% %%
% function [ dirList ] = getDirListForMotionCorrectedNii(analysisDir, subject, realignBaseDir)
%     motionCorrBase = [analysisDir, subject, filesep, realignBaseDir];
%     dirStruct = dir([motionCorrBase,'*']);
%     dirList = cellfun(@(d,s) [char(d),filesep,char(s),filesep],{dirStruct.folder},{dirStruct.name},'UniformOutput',false)';
% end
