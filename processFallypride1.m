
%% CMDLINE RUN
% /Applications/MATLAB_R2016b.app/bin/matlab -nodisplay -r "addpath(genpath('/Users/subravcr/Projects/zaldlab-fallypride'));processFallypride1;exit;"

%% DEFAULT PARAMETER setup block
% default parameters
default_params=@defaults_fallypride;
% Change Default parameters globally for this run
defaults.analysisDir = '/Users/subravcr/teba/zaldlab-chenchal/Apr-12-1/Scan-1/';

%% SUBJECT Block
% Subject List
subjects = {
    'DND005' %not good align - set 0
    'DND007'
    %     'DND014' %not good align - set 0,1,2
    %     'DND016' %not good align - set 0
    %     'DND018'
    %     'DND022' %not good align - set 0,1,2
    %     'DND023'
    };

%% EXCEPTIONS BLOCK to Default parameters per subject
DND005.pmodNiiFileExt = '_Sess1_all_dy.nii';
DND005.t1Bet=[0 0.6];
DND005.petBet=[0 0.3 0.4];

%% Call for Processing
processPet;