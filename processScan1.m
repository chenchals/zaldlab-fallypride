
% Creates preprocessed analysis output directory structure (created if not exist)
%   [analysisDir]
%   [analysisDir]/subject : For converted files
%   [analysisDir]/[subject]/[realignDirBase]0
%   [analysisDir]/[subject]/[realignDirBase]1 vol0000.nii dropped
%   [analysisDir]/[subject]/[realignDirBase]2 vol0000.nii and vol0002.nii dropped
%
%  Base directory path for each subject processing ** ends in a / ***
analysisDir = '/Users/subravcr/teba/zaldlab-chenchal/Mar-17Final/Scan-1/';
% Input arguments for Processing
% Base directory path for subject dcm and PMOD_Processed files
dataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/Fallypride/Scan_1/';
pmodNiiFileExtension='_Sess1_all_dy.nii';
pmodAcqtimeFileExtension='_Sess1.acqtimes';
% T1_2_mni files for each subject located under [mriDataDir]/subject/T1_2mni
mriDataDir ='/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/';
% Analysis subdir name
% Generates a set of 3 sub dirs under the analyisDir/subject corresponding
% to 0, 1, or 2 initial nii vols dropped for motion correction
realignDirBase = 'analysis-set';
% Bet params for PET scans
petBet=[0, 0.3,0.4,0.5,0.6];
% Bet params for T1 Structural scans
t1Bet=[0, 0.4, 0.5];
% Decay constant for F18 Fallypride in Minutes
decayConstant = 109.77;
% Subject list
subjects = {
    'DND005' %not good align - set 0
    'DND007'
    'DND014' %not good align - set 0,1,2
    'DND016' %not good align - set 0
    'DND018'
    'DND022' %not good align - set 0,1,2
    'DND023'
    'DND027' % different dir structure
    'DND031'
    'DND032' %not good align - set 0,1,2
    'DND037' % different dir structure
    'DND039'
    'DND040' %not good align - set 0,1,2
    'DND041' % different dir structure
    'DND042' %not good align - set 0,1,2
    'DND048' %not good align - set 0,1,2
    'DND050' %not good align - set 0,1,2
    'DND052' %not good align - set 0,1,2
    'DND060'
    'DND062' % different dir structure
    'DND069' % different dir structure
    'DND072'
    };

% For coregister
meanVol = 'meanvol0019';
coWipT1Sense = 'coWIPT1W3DTFESENSEs002a001';
cerebellumT1gz = 'cerebellum_T1space.nii.gz';
putamenT1gz = 'putamen_T1space.nii.gz';

process;