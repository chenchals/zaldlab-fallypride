function [ defaults ]=defaults_fallypride()
    defaults.subject = '';
    defaults.dataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/Fallypride/Scan_1/';
    defaults.mriDataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/';
    defaults.analysisDir = '/Users/subravcr/teba/zaldlab-chenchal/Apr-11-4/Scan-1/';
    defaults.realignBaseDir = 'analysis-set';
    % Subject's PMD analysis dir 
    defaults.pmodAnalysisDir = 'Decay/PMOD_Processed';
    % PMOD nii file [defaults.subject]_Sess1_all_dy.nii
    defaults.pmodNiiFileExt = '_Sess1_all_dy.nii';    
    % PMOD acq times file [defaults.subject]_Sess1.acqtimes
    defaults.pmodAcqtimeFileExt ='_Sess1.acqtimes';
    defaults.numberOfVols = 35;    
    % Counts to Bq correction flag set only of the PET nii are counts
    % Since we are using PMOD 4D nii file, the counts are already converted
    % to mBq by PMOD
    defaults.countsToBacquerel = false;
    % Decay correction for PET scans done at Gaps DY2, DY3..
    defaults.doDecayCorrection=true;
    % Decay constant in minutes
    defaults.decayConstant = 109.77;
    % Include only those for which decay correction are needed
    defaults.decayCorrectionFileSuffix='_dc';
    % List of nii volumes to apply decay correction Zero-based
    defaults.decayCorrectionVolSets = {
        {'vol0028' 'vol0029' 'vol0030' 'vol0031'}  % DY2
        {'vol0032' 'vol0033' 'vol0034'}            % DY3
        };
    % Motion correction reference Volume
    defaults.motionCorrectionRefVol = 'vol0019';
    % [defaults.realignBaseDir]0 will contain analyses with all vols
    defaults.motionCorrectionVolSetsToExclude={
        {'vol0000'} % Analyses outputs in [defaults.realignBaseDir]1
        {'vol0000' 'vol0001'} % Analyses outputs in [defaults.realignBaseDir]2
        };
    % Co-register bet for mean PET vol thresholded
    defaults.mniBaseDir='T1_2_MNI';
    defaults.coWipT1Sense = 'coWIPT1W3DTFESENSEs002a001.nii';
    %  Subject BET -f values for T1 scan
    defaults.t1Bet = [0, 0.4, 0.5];
    % Subject Brain ROIs in T1 Space
    defaults.brainT1Rois = {
        'cerebellum_T1space.nii.gz'
        'putamen_T1space.nii.gz'
        };
    
    %Subject mean thresholded motion corrected volume to use for
    %Co-register with Subject T1
    % mean[defaults.motionCorrectionRefVol]_thr is used example : 'meanvol0019_thr'
    %  Subject BET -f values for PET scans
    defaults.petBet = [0, 0.3,0.4,0.5,0.6];

end