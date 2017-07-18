function [ defaults ]=defaultsPe2i()

%% LOCATIONS OF STUDY & FILENAMES PATTERNS
    defaults.subject = '';
    defaults.dataDir = '';
    defaults.mriDataDir = '';
    defaults.analysisDir = '';
    defaults.realignBaseDir = '';
    % Subject's PMOD analysis dir 
    defaults.pmodAnalysisDir = '';
    % PMOD nii file [defaults.subject]_Sess1_all_dy.nii
    defaults.pmodNiiFileExt = '';    
    % PMOD acq times file [defaults.subject]_Sess1.acqtimes
    defaults.pmodAcqtimeFileExt ='';
    defaults.numberOfVols = 28;    
    
    %% DECAY CORRECTION PARAMETERS BLOCK
    
    % Counts to Bq correction flag set only of the PET nii are counts
    % Since we are using PMOD 4D nii file, the counts are already converted
    % to mBq by PMOD
    defaults.countsToBacquerel = false;
    % Decay correction for PET scans done at Gaps DY2, DY3..
    defaults.doDecayCorrection=false;
    % Decay constant in minutes
    defaults.decayConstant = 0;
    % Include only those for which decay correction are needed
    defaults.decayCorrectionFileSuffix='';
    % List of nii volumes to apply decay correction Zero-based
    defaults.decayCorrectionVolSets = {
        };

    %% MOTION CORRECTION PARAMETERS BLOCK

    % Motion correction reference Volume
    defaults.motionCorrectionRefVol = 'vol0019';
    % [defaults.realignBaseDir]0 will contain analyses with all vols
    defaults.motionCorrectionVolSetsToExclude={
        {'vol0000'} % Analyses outputs in [defaults.realignBaseDir]1
        {'vol0000' 'vol0001'} % Analyses outputs in [defaults.realignBaseDir]2
        };

    %% COREGISTRATION PARAMETERS BLOCK

    % Coregister bet for mean PET vol thresholded
    defaults.mniBaseDir='T1_2_MNI/';
    defaults.coWipT1Sense = 'coWIPT1W3DTFESENSEs002a001.nii';
    %  Subject BET -f values for T1 scan
    defaults.t1Bet = [0, 0.4, 0.5];
    % Subject Brain ROIs in T1 Space
    defaults.brainT1Rois = {
        'cerebellum_T1space.nii.gz'
        'putamen_T1space.nii.gz'
        };
    % Thresholds for the ROIs in PET space
    defaults.roiThresholds = [0.99 1];
    %  Subject BET -f values for PET scans
    defaults.meanPetVolThreshold = 1;
    defaults.petBet = [0, 0.3,0.4,0.5,0.6];

end