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
    meanPetVolThreshold = params.meanPetVolThreshold;
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
        threshold = meanPetVolThreshold;
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
    cmdStr = ['rm -rf ' subjectTempDir];
    logger.info(cmdStr);
    system(cmdStr,'-echo');
    cd(currentDir); % change back to the directory fo this file
end

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

