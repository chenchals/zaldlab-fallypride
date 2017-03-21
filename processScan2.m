
% Creates preprocessed analysis output directory structure (created if not exist)
%   [analysisDir]
%   [analysisDir]/subject : For converted files
%   [analysisDir]/[subject]/[realignDirBase]0
%   [analysisDir]/[subject]/[realignDirBase]1 vol0000.nii dropped
%   [analysisDir]/[subject]/[realignDirBase]2 vol0000.nii and vol0002.nii dropped
%
%
    %  Base directory path for each subject processing
    analysisDir = '/Users/subravcr/teba/zaldlab-chenchal/Mar-20-Final/Scan-2/';
    % Input arguments for Processing
    % Base directory path for subject dcm and PMOD_Processed files
    dataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/Fallypride/Scan_2/';
    pmodNiiFileExtension='_Sess2_all_dy.nii';    
    pmodAcqtimeFileExtension='_Sess2.acqtimes';
    % T1_2_mni files for each subject located under [mriDataDir]/subject/T1_2mni
    mriDataDir ='/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/';
    % Realign sub-dir name.
    % Generates a set of 3 sub dirs under the analyisDir/subject corresponding
    % to 0,1, or 2 initial nii vols dropped for motion correction
    realignDirBase = 'analysis-set';

    petBet=[0, 0.3,0.4,0.5,0.6];
    t1Bet=[0, 0.4, 0.5];
    % Decay constant for F18 Fallypride in Minutes
    decayConstant = 109.77;

    subjects = {
        'DND005'
        'DND007'
        'DND014'
        'DND016'
        'DND018'
        'DND022'
        'DND023'
        'DND027'
        'DND031'
        'DND032'
        'DND037'
        'DND041'
        'DND042'
        'DND048'
        'DND050'
        'DND052'
        'DND062'
        'DND069'
        'DND072'
        };
    
    % For coregister
    meanVol = 'meanvol0019';
    coWipT1Sense = 'coWIPT1W3DTFESENSEs002a001';
    cerebellumT1gz = 'cerebellum_T1space.nii.gz';
    putamenT1gz = 'putamen_T1space.nii.gz';
    
    process;