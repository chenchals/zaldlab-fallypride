function coregisterMeanPetWithT1( analyisDir, realignBaseDir, mriDataDir, subject, t1Bet, petBet )
%COREGISTERMEANPETWITHT1 Summary of this function goes here
%   Detailed explanation goes here
    global meanVolThr;
    global cerebellumT1gz;
    global putamenT1gz;
    
    batchFunction='coregisterMeanPetWithT1';
    % Set fsl output to nii
    setenv('FSLOUTPUTTYPE','NIFTI');
    fprintf('\nProcessing for subject: %s\t%s\n',subject,batchFunction);

    % keep track of the where this function is
    currentDir = pwd;
    %% Filenames
    % For thresholding
    meanVol = 'meanvol0019';
    %meanVolThr = 'meanvol0019_thr';
    % For coregister
    coWipT1Sense = 'coWIPT1W3DTFESENSEs002a001';
    t1BetFvals=t1Bet;
    coWipT1SenseBet{3}=[];
    % Cerebellum T1
    cerebellumT1gz = 'cerebellum_T1space.nii.gz';
    % Putamen T1
    putamenT1gz = 'putamen_T1space.nii.gz';
    
    %% Call fsl functions for each realigned set
    
    motionCorrDirs = getDirListForMotionCorrectedNii(analyisDir, subject, realignBaseDir);
    t1Dir = [mriDataDir, subject, filesep, 'T1_2_MNI', filesep];
    petBetFvals=petBet;
    % for each analysis dir of motion corrected files
    for ii=1:length(motionCorrDirs)
        petDir = [char(motionCorrDirs{ii}),filesep];
        fprintf('\n\t%s: Processing for subject: %s analysis dir:%s\n',batchFunction,subject,petDir);

        % All relevant files in this dir, so do analysis here
        cd(petDir); % end of this fx change back to the currentDir location
        % Copy coWIPTI...nii, cerebellum_T1..nii.gz, and
        % putamen_T1....nii.gz to petDir

        callSystem(['cp ', [t1Dir,cerebellumT1gz], ' ', [petDir,cerebellumT1gz]]);
        callSystem(['cp ', [t1Dir,putamenT1gz], ' ', [petDir,putamenT1gz]]);
        
        if(ii==1)
           % Create Bet T1 images
           coWipT1SenseBet{1}=[coWipT1Sense,'.nii'];
           callSystem(['cp ', [t1Dir,char(coWipT1SenseBet{1})], ' ', [petDir,char(coWipT1SenseBet{1})]]);
           for t1=2:length(t1BetFvals)
                t1BetVal = t1BetFvals(t1);
                coWipT1SenseBet{t1}=[coWipT1Sense,'_bet_f',regexprep(num2str(t1BetVal),'\.',''),'.nii'];
                 %bet coWIP and write to same dir
                fslBet(coWipT1SenseBet{1}, char(coWipT1SenseBet{t1}), t1BetVal);  
            end
        else
            callSystem(['cp ', [char(motionCorrDirs{1}),filesep,coWipT1Sense,'*'], ' ', petDir]);
        end        
        % For thresholding
        meanVolThr = 'meanvol0019_thr';
        % Threshold the mean volume
        fprintf('\n\t%s: Computing thresholded mean vol for subject: %s\n',batchFunction,subject);
        fslThresholdVolume(meanVol, meanVolThr, 1);
        % No Bet process
        processCoregistration(petDir, petBetFvals(1), t1BetFvals(1), char(coWipT1SenseBet{1}));
        for petBet=2:length(petBetFvals)
            for t1Bet=2:length(t1BetFvals) % t1s already bet-ed
                processCoregistration(petDir, petBetFvals(petBet), t1BetFvals(t1Bet), char(coWipT1SenseBet{t1Bet}));
            end
        end
        
    end % for each
    cd(currentDir); % change back to the directory fo this file
end

%% Compute coregister steps for each BET
function processCoregistration(analysisDir, petBetFval, t1BetFval, coWipT1SenseFile)
    global meanVolThr;
    global cerebellumT1gz;
    global putamenT1gz;
    t1PetBetSuffix = '';
    petBetSuffix = '';
    % change filenames for bet
    if(petBetFval>0)
        t1PetBetSuffix = regexprep(['_bet_','T1f',num2str(t1BetFval),'_','PETf',num2str(petBetFval)],'\.','');
        petBetSuffix = regexprep(['_bet_','PETf',num2str(petBetFval)],'\.','');
    end
    meanVolThrBet =[meanVolThr, petBetSuffix];
    % For coregister
    coWipT1SenseBet = coWipT1SenseFile;
    T1_2_meanVolBet = ['T1_2_meanvol', t1PetBetSuffix];
    meanVol_2_T1Bet = ['meanvol_2_T1', t1PetBetSuffix];
    % Cerebellum PET space for subject
    cerebellumInPetSpaceBet = ['cerebellum_in_PETspace', t1PetBetSuffix];
    % Putamen PET space for subject
    putamenInPetSpaceBet = ['putamen_in_PETspace', t1PetBetSuffix];

    % Extract Brain (remove skull)
    if(petBetFval>0)
        fprintf('\n\t\t Removing skull through FSL-BET with a -f =%s for analysis dir %s\n',num2str(petBetFval), analysisDir);
        % cmd bet inF oF  -f 0.5 -g 0  (output use thr_brain_bet_f05)
        % bet mean Thr vol
        fslBet(meanVolThr, meanVolThrBet, petBetFval);
    else
        fprintf('\n\t\t Without FSL-BET for analysis dir %s\n',analysisDir);
    end

    % Coregister T1 to PET
    fslCoregister(coWipT1SenseBet, meanVolThrBet, T1_2_meanVolBet, meanVol_2_T1Bet);

    % Move cerebellum T1 to PET space
    fslMoveRoiFromT1ToPet(cerebellumT1gz, meanVolThrBet, T1_2_meanVolBet, cerebellumInPetSpaceBet);
    fslThresholdVolume(cerebellumInPetSpaceBet, [cerebellumInPetSpaceBet,'_thr'], 1);

    % Move putamen T1 to PET space
    fslMoveRoiFromT1ToPet(putamenT1gz, meanVolThrBet, T1_2_meanVolBet, putamenInPetSpaceBet);
    fslThresholdVolume(putamenInPetSpaceBet, [putamenInPetSpaceBet,'_thr'],0.99);
end


%% Threshold PET mean volume
function fslThresholdVolume(volFile, volThrFile, thresholdValue)
    % Threshold the mean volume
    cmdStr = ['fslmaths ',volFile,' -thr ', num2str(thresholdValue),' ', volThrFile];
    callSystem(cmdStr);
end

%% Coregister T1 to PET
function fslCoregister(coWipT1SenseFile, meanVolThrFile, t1ToMeanVolFile, meanVolToT1File)
    % coregister
    cmdStr = ['flirt -in ', coWipT1SenseFile, ' -ref ', meanVolThrFile, ' -dof 6 -out ', t1ToMeanVolFile, ' -omat ', t1ToMeanVolFile, '.mat'];
    callSystem(cmdStr);
    % Create inverse xFrom matrix
    invCmdStr = ['convert_xfm -omat ', meanVolToT1File, '.mat', ' -inverse ', t1ToMeanVolFile, '.mat'];
    callSystem(invCmdStr);
end

%% Move ROI from T1 to PET space
function fslMoveRoiFromT1ToPet(roiT1File, meanVolThrFile, t1ToMeanVolMatFile, roiPetFile)
    % Threshold the mean volume
    cmdStr = ['flirt -in ', roiT1File, ' -ref ', meanVolThrFile, ' -applyxfm -init ', t1ToMeanVolMatFile, '.mat', ' -out ', roiPetFile];
    callSystem(cmdStr);
end

%%
function fslBet(inFile, outFile, fval)
    % call Bet tfor brain extraction (remove  skull)
    cmdStr = ['bet ', inFile, ' ', outFile, ' -f ', num2str(fval), ' -g 0'];
    callSystem(cmdStr);
end

%%
function callSystem(cmdLine)
    % Execute the commands on system OS
    disp(cmdLine)
    system(cmdLine);
end

%%
function [ dirList ] = getDirListForMotionCorrectedNii(analysisDir, subject, realignBaseDir)
    motionCorrBase = [analysisDir, subject, filesep, realignBaseDir];
    dirStruct = dir([motionCorrBase,'*']);
    dirList = cellfun(@(d,s) [char(d),filesep,char(s),filesep],{dirStruct.folder},{dirStruct.name},'UniformOutput',false)';
end
