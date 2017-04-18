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

%% DEFAULT PARAMETER setup block
% default parameters
default_params=@defaults_fallypride;
% Change Default parameters globally for this run
defaults.dataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/Fallypride/Scan_1/';
defaults.mriDataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/';
defaults.analysisDir = '/Users/subravcr/teba/zaldlab-chenchal/Apr-12-2/Scan-1/';
defaults.realignBaseDir = 'analysis-set';
% Subject's PMOD analysis dir
defaults.pmodAnalysisDir = 'Decay/PMOD_Processed';
% PMOD nii file [defaults.subject]_Sess1_all_dy.nii
defaults.pmodNiiFileExt = '_Sess1_all_dy.nii';
% PMOD acq times file [defaults.subject]_Sess1.acqtimes
defaults.pmodAcqtimeFileExt ='_Sess1.acqtimes';
defaults.numberOfVols = 35;


%% SUBJECT Block
%% All subjects
allSubjects = getAllSubjects([defaults.dataDir, 'DND*']);
subjects = allSubjects;
%% Subject List
% subjects = {
%     'DND040' 
%     'DND007'
%     };

%% EXCEPTIONS BLOCK to Default parameters per subject
DND005.pmodNiiFileExt = '_Sess1_all_dy.nii';
DND005.t1Bet=[0 0.6];
DND005.petBet=[0 0.3 0.4];


    DND005.motionCorrectionRefVol = 'vol0017';
    % [defaults.realignBaseDir]0 will contain analyses with all vols
    DND005.motionCorrectionVolSetsToExclude={
        {'vol0000'} % Analyses outputs in [defaults.realignBaseDir]1
        {'vol0000' 'vol0001'} % Analyses outputs in [defaults.realignBaseDir]2
        {'vol0019' } % Analyses outputs in [defaults.realignBaseDir]2
        };

%% Call for Processing
processPet;

%% function to get all subjects
function subjects = getAllSubjects(dirFilter)
  dList = dir(dirFilter);
  subjects = {dList.name};
end
