function [ realignSets ] = realignEstimateReslice(niiBaseDir, realignBaseDir, subject)
%REALIGNESTIMATERESLICE Motion correction for NIfTI images
%Note correction is specific to studies of Fallypride. The function
%Excepts the following Directory structure and filename pattern:
%ANALYSIS_DIR
%  |---SUBJECT1
%        |---vol0000.nii to vol0027.nii (28 volumes corresponding to DY1)
%        |---vol0028_dc.nii to vol0031_dc.nii  (4 volumes corresponding to DY2)
%        |---vol0032_dc.nii to vol0033_dc.nii  (3 volumes corresponding to DY3)
%   Inputs:
%   niiBaseDir : Folder containing subject vol*.nii files described above
%   realignBaseDir : Folder for Motion corrected files and meanvol files
%   subject : Subject folder name 
%
%Output folder/file structure
%
%ANALYSIS_DIR
%  |---SUBJECT1
%         |---[realignBaseDir]0
%         |                 |---rvol0000.nii to rvol0027.nii
%         |                 |---rvol0028_dc.nii to rvol0031_dc.nii  
%         |                 |---rvol0032_dc.nii to rvol0033_dc.nii  
%         |                 |---meanvol0019.nii  
%         |                 |---other mat file of SPM job  
%         |
%         |---[realignBaseDir]1 (drop vol0000.nii for motion correction)
%         |                 |---rvol0001.nii to rvol0027.nii
%         |                 |---rvol0028_dc.nii to rvol0031_dc.nii  
%         |                 |---rvol0032_dc.nii to rvol0033_dc.nii  
%         |                 |---meanvol0019.nii  
%         |                 |---other mat file of SPM job  
%         |
%         |---[realignBaseDir]2 (drop vol0000.nii and vol0001.nii for motion correction)
%         |                 |---rvol0000.nii to rvol0027.nii
%         |                 |---rvol0028_dc.nii to rvol0031_dc.nii  
%         |                 |---rvol0032_dc.nii to rvol0033_dc.nii  
%         |                 |---meanvol0019.nii  
%         |                 |---other mat file of SPM job  
%         |
%
%   Outputs:
%   realignSets : Lists of nii files used for motion correction
%
%   Example:
%   realignSets = realignEstimateReslice(niiBaseDir, realignBaseDir, subject)
%   CONVERT2NII('[teba-location-analysis-dir/','analysis-set ,'DND005')
%
%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
    batchFunction='realignEstimateReslice';
    fprintf('\nProcessing for subject: %s\t%s\n',subject,batchFunction);

    % Process spm batch for job
    % Initialize subject specific variables
    initObj=initializeVars(niiBaseDir, subject);
    realignList=initObj.realignList;
    realignSets{3}=[]; % initialize cell array
    % Run current job function, passing along subject-specific inputs
    notUsingFiles = '[Using all volumes]';
    for ii=1:3 % Run 3 realignments
        if (ii>1)
            offsetIndex = ii + 1; % vol offset 2 for set 1
            initObj.realignList=[realignList(1); realignList(offsetIndex:length(realignList))];
            if(ii==2)
                notUsingFiles='Not using [vol000.nii]';
            elseif(ii==3)
                notUsingFiles='Not using [vol000.nii, vol0001.nii]';
            end
        end
       fprintf('\n\t%s: For subject: %s\t%s\n', batchFunction, subject, notUsingFiles);
        
        % Run current job function, passing along subject-specific inputs
        batchJob{1} = createJob(initObj);
        spm('defaults','PET');
        spm_jobman('initcfg');
        
        jobOutput = spm_jobman('run', batchJob);
        %spm_realign(initObj.realignList);
        
        % Save output (e.g., matlabbatch) for future reference
        outName = strcat(initObj.niiDir,filesep,subject,'_',batchFunction,'_set_',num2str(ii-1));
        save(outName, 'batchJob');
        save([outName,'_jobOutput'], 'jobOutput');
        
        % Copy / rename files and move to appropriate sub-directory
        realignedDir=[initObj.niiDir, filesep, realignBaseDir, num2str(ii-1)];
        mkdir(realignedDir);
        copyfile([initObj.niiDir,filesep,'r*.*'], [realignedDir, filesep,'.']);
        delete([initObj.niiDir,filesep,'r*.*']);
        copyfile([initObj.niiDir,filesep,'mean*.*'], [realignedDir, filesep,'.']);
        delete([initObj.niiDir,filesep,'mean*.*']);
        copyfile([initObj.niiDir,filesep,'*_set_*.*'], [realignedDir, filesep,'.']);
        delete([initObj.niiDir,filesep,'*_set_*.*']);
        % Other outputs
        realignSets{ii,1} = initObj.realignList;
                
        
        % Clear Job vars
        clear jobs outName batchJob jobOutput harvestedJob        
        
    end
end

% Initialize variables
function [ initObj ] = initializeVars(niiBaseDir, subject)
    % SPM info
    initObj.spmDir = fileparts(which('spm'));

    % Input
    initObj.subject = subject;
    initObj.outDir = niiBaseDir;
    % Directory containing the nii files
    initObj.niiDir = strcat(niiBaseDir,initObj.subject);

    % Order of nii files for realign
    refVolume=19;
    volsDY1=num2cell([refVolume,0:refVolume-1,refVolume+1:27]);
    % Non-decay corrected files
    listDY1=cellfun(@(x) [initObj.niiDir,filesep,'vol',num2str(x,'%04d'),'.nii,1'], ...
        volsDY1,'UniformOutput',false);
    % Decay corrected files
    volsDY23=num2cell([28:34]);
    listDY23=cellfun(@(x) [initObj.niiDir,filesep,'vol',num2str(x,'%04d'),'_dc.nii,1'], ...
        volsDY23,'UniformOutput',false);
    % Merge file lists
    initObj.realignList = [listDY1,listDY23]';
    
end 

% Create matlabbatch job
function [ matlabbatch ] = createJob(initVars)
    matlabbatch.spm.spatial.realign.estwrite.data = {initVars.realignList};
    matlabbatch.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.sep = 4;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.rtm = 1;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.interp = 2;
    matlabbatch.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
    matlabbatch.spm.spatial.realign.estwrite.eoptions.weight = '';
    matlabbatch.spm.spatial.realign.estwrite.roptions.which = [2 1];
    matlabbatch.spm.spatial.realign.estwrite.roptions.interp = 4;
    matlabbatch.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
    matlabbatch.spm.spatial.realign.estwrite.roptions.mask = 1;
    matlabbatch.spm.spatial.realign.estwrite.roptions.prefix = 'r';
  
end

