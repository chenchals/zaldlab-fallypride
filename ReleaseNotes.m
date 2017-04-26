% Main PET processing workflow was developed in consultation with Chris in Dr. Zald's lab. 
% Chris has also been verifying all the processing steps in this project.  
% Linh helped with identifying user modifiable parameters adapting pipeline
% to other radionucleides used in PET studies.
% Author: Chenchal Subraveti
% Copyright: Zald Lab
%
% Modification Logs
% Use: git log --date=short --pretty=format:"%% %cd %s"
%
% 2017-04-26 updated shellScript for running batch process from terminal window in fsl-vm
% 2017-04-26 Removed unused functions/files and moved processing modules to sub-dir
% 2017-04-26 Added releasee notes
% 2017-04-26 Removed for consistent file naming
% 2017-04-26 Updated files after running for Fallypride and PE2I
% 2017-04-18 updated release notes
% 2017-04-18 Updated with writing acqTimes file for PMOD for each analysis set.
% 2017-04-18 Updated while working with Linh
% 2017-04-12 Updated for writing Error log
% 2017-04-12 Updated for co-register
% 2017-04-11 Updated for pet/T1 bet computation
% 2017-04-11 Updated for Realign / motion correction - replaced with params structure for argument
% 2017-04-10 updated for no decay correction and no counts to mBq
% 2017-04-10 Updated for logger and decay correction steps
% 2017-03-28 Merge branch 'release/preprocess_Scan1_Scan2' into develop
% 2017-03-21 Final update before review
% 2017-03-17 updated scripts
% 2017-03-17 counts to Becquerel correction flag
% 2017-03-17 variables are now a structure
% 2017-03-15 Removed files not needed
% 2017-03-15 Updated for normalizing and pulling out vars - using evalin
% 2017-03-15 Pruned files for pre processing Fallypride Scan1 and Scan2.
% 2017-03-15 Updated for Scan2
% 2017-02-07 initial commit
