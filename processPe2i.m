
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
% /usr/local/bin/matlab -nodisplay -r "addpath(genpath('/mnt/teba/Active_Lab_Projects/Chenchal/Code/zaldlab-fallypride'));processPe2i;exit;"

%% DEFAULT PARAMETER setup block
% default parameters
default_params=@defaultsPe2i;
% Change Default parameters globally for this run
rootDataDir = '/mnt/teba/';
rootAnalysisDir = '/mnt/teba2016/Chenchal/Apr-25-1/';
% Directory name prefix for each subject: DND005, DND017, etc
subjectDirNamePrefix = 'DND*';
defaults.dataDir = [rootDataDir 'Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/PE2I/'];
defaults.mriDataDir =[rootDataDir 'Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/'];
defaults.analysisDir = [rootAnalysisDir 'PE2I/'];
defaults.realignBaseDir = 'analysis-set';

% Subject's PMOD analysis dir
defaults.pmodAnalysisDir = 'Decay/PMOD_Processed';
% PMOD nii file [defaults.subject]_PE2I_all_dy.nii
defaults.pmodNiiFileExt = '_PE2I_all_dy.nii';
% PMOD acq times file [defaults.subject]_PE2I.acqtimes
defaults.pmodAcqtimeFileExt ='_PE2I.acqtimes';
defaults.numberOfVols = 28;

%% SUBJECT Block
%% All subjects
allSubjects = dir([defaults.dataDir, subjectDirNamePrefix]);
allSubjects = {allSubjects.name};
subjects = allSubjects;
%% Subject List
% subjects = {
%     'DND018' 
%     };

%% EXCEPTIONS BLOCK to Default parameters per subject
%% DND078 Exceptions
DND078.coWipT1Sense = 'DND078_T1.nii.gz';

%% DND072 Exceptions
DND072.coWipT1Sense = 'DND072_T1.nii.gz';
    DND072.brainT1Rois = {
        'cerebellum_T1space.nii'
        'putamen_T1space.nii'
        };

%% DND041 Exceptions
DND041.pmodAnalysisDir = '90min/';
DND041.pmodAcqtimeFileExt ='.acqtimes';
DND041.numberOfVols = 30;
% [defaults.realignBaseDir]0 will contain analyses with all vols
DND041.motionCorrectionVolSetsToExclude={
    {'vol0028' 'vol0029'} % Analyses outputs in [defaults.realignBaseDir]1
    };

%% DND031 Exceptions
DND031.pmodAnalysisDir = '90min/';
DND031.pmodAcqtimeFileExt ='.acqtimes';
DND031.numberOfVols = 30;
% [defaults.realignBaseDir]0 will contain analyses with all vols
DND031.motionCorrectionVolSetsToExclude={
    {'vol0028' 'vol0029'} % Analyses outputs in [defaults.realignBaseDir]1
    };

%% DND083 Exceptions
DND083.dataDir = '/mnt/teba2016/DND_PET_data/PE2I/';

%% DND029 Exceptions
DND029.pmodAnalysisDir = '90min/';
DND029.pmodAcqtimeFileExt ='.acqtimes';
DND029.numberOfVols = 30;
% [defaults.realignBaseDir]0 will contain analyses with all vols
DND029.motionCorrectionVolSetsToExclude={
    {'vol0028' 'vol0029'} % Analyses outputs in [defaults.realignBaseDir]1
    };

%% DND023 Exceptions
DND023.pmodAnalysisDir = '90min/';
DND023.pmodAcqtimeFileExt ='.acqtimes';
DND023.numberOfVols = 30;
% [defaults.realignBaseDir]0 will contain analyses with all vols
DND023.motionCorrectionVolSetsToExclude={
    {'vol0028' 'vol0029'} % Analyses outputs in [defaults.realignBaseDir]1
    };
% 
%% Call for Processing
processPet;
