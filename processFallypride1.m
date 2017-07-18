%% Required setup for Matlab
% ********************* Required ********************
% Notes to execute fslmaths from within Matlab, include the following lines
% in the startup.m file, then run startup.m or restart matlab
% In terminal window run: which fsl to get the install location of fsl
% Example: /usr/local/fsl/bin/fsl ==> fsldir = /usr/local/fsl
% >>edit startup.m
%     fsldir = '/usr/local/fsl';
%     setenv('FSLDIR', fsldir);
%     setenv('PATH',[fsldir, '/etc/matlab:', fsldir, '/bin:', fsldir, '/etc/fslconf:', getenv('PATH')]);
%     % Check http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslEnvironmentVariables
%     setenv('FSLOUTPUTTYPE','NIFTI');
%     clear 'fsldir'
% ***************************************************

%% CMDLINE RUN
% /Applications/MATLAB_R2016b.app/bin/matlab -nodisplay -r "addpath(genpath('/Users/subravcr/Projects/zaldlab-fallypride'));processFallypride1;exit;"
% /usr/local/bin/matlab -nodisplay -r "addpath(genpath('/mnt/teba/Active_Lab_Projects/Chenchal/Code/zaldlab-fallypride'));processFallypride1;exit;"

%% DEFAULT PARAMETER setup block
% default parameters
default_params=@defaultsFallypride;
% Change Default parameters globally for this run
rootDataDir = '/Volumes/zaldlab/';
rootAnalysisDir = '/Volumes/zaldlab2016/Chenchal/May-12-1/';
% Directory name prefix for each subject: DND005, DND017, etc
subjectDirNamePrefix = 'DND*';
defaults.dataDir = [rootDataDir 'Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/Fallypride/Scan_1/'];
defaults.mriDataDir =[rootDataDir 'Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/'];
defaults.analysisDir = [rootAnalysisDir 'Fallypride/Scan-1/'];
defaults.realignBaseDir = 'analysis-set';
% Subject's PMOD analysis dir
defaults.pmodAnalysisDir = 'Decay/PMOD_Processed/';
% PMOD nii file [defaults.subject]_Sess1_all_dy.nii
defaults.pmodNiiFileExt = '_Sess1_all_dy.nii';
% PMOD acq times file [defaults.subject]_Sess1.acqtimes
defaults.pmodAcqtimeFileExt ='_Sess1.acqtimes';
defaults.numberOfVols = 35;

%% SUBJECT Block
%% All subjects
allSubjects = dir([defaults.dataDir, subjectDirNamePrefix]);
allSubjects = {allSubjects.name};
subjects = allSubjects;
%% Subject List
subjects = {
    'DND005' 
    'DND007'
    'DND011'
    };

%% EXCEPTIONS BLOCK to Default parameters per subject
% % Exceptions for DND040 (Scan_2 not present for subject)
% DND040.mriDataDir = '/mnt/teba/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/';
% DND040.mniBaseDir='Scan_2/T1_2_MNI/';
% DND040.brainT1Rois = {
%     'cerebellum_T1space.nii'
%     'putamen_T1space.nii'
%     };
% 
% % Exceptions for DND032
% DND032.pmodAnalysisDir = 'Decay/PMOD_Processed/Rerun_from_Beginning_4_11_17/';
% 
% % Exceptions for DND074
% DND074.coWipT1Sense = 'DND074_T1.nii';
% 
% % Exceptions for DND072
% DND072.coWipT1Sense = 'DND072_T1.nii.gz';
% DND072.brainT1Rois = {
%     'cerebellum_T1space.nii'
%     'putamen_T1space.nii'
%     };
%     
% % Exceptions for DND078
% DND078.coWipT1Sense = 'DND078_T1.nii.gz';
% 
% % Exceptions for DND080
% DND080.coWipT1Sense = 'DND080_T1.nii.gz';
% 
% % Exceptions for DND084
% DND084.coWipT1Sense = 'coWIPWIPT1W3DTFESENSEs002a001.nii';


%% Call for Processing
processPet;
