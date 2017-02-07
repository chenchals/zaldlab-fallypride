function process(stepName)
% Creates preprocessed analysis output directory structure (created if not exist)
%   [analysisDir]
%   [analysisDir]/subject : For converted files
%         vol00xx*.nii, as well as vol00xx_dc.nii (decay corrected)
%         [subject]_acquisitionTimes.acqtimes,
%         and SPM(8/12) matlabbatchjob files
%         [subject]_Convert2Nii_jobOutput.mat
%         [subject]_Convert2Nii.mat
%   [analysisDir]/[subject]/[realignDirBase]0
%   [analysisDir]/[subject]/[realignDirBase]1 vol0000.nii dropped
%   [analysisDir]/[subject]/[realignDirBase]2 vol0000.nii and vol0002.nii dropped
%
%

    disp(['Doing Step: ' stepName ]);

    petBet=[0, 0.3,0.4,0.5,0.6];
    t1Bet=[0, 0.4, 0.5];
    % get and set paths
    scriptdir = pwd;
    addpath(scriptdir);

    %  Base directory path for each subject processing
    analysisDir = '/Users/subravcr/teba/zaldlab-chenchal/Feb-1/';

    % Input arguments for Processing
    % Base directory path for subject dcm files
    dataDir = '/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/PET_Data/Scan/Fallypride/Scan_1/';

    % T1_2_mni files for each subject located under [mriDataDir]/subject/T1_2mni
    mriDataDir ='/Users/subravcr/teba/zaldlab/Active_Lab_Projects/DANeuromodulation/MRI_Data/DND_Scans/';


    % Realign sub-dir name.
    % Generates a set of 3 sub dirs under the analyisDir/subject corresponding
    % to 0,1, or 2 initial nii vols dropped for motion correction
    realignDirBase = 'analysis-set';

    % Decay constant for F18 Fallypride in Minutes
    decayConstant = 109.77;

    subjects = {
%         'DND005' %not good align - set 0
%         'DND007'
        'DND014' %not good align - set 0,1,2
%         'DND016' %not good align - set 0
%         'DND018'
%         'DND022' %not good align - set 0,1,2
%         'DND023'
%         'DND027' % different dir structure
%         'DND031'
%         'DND032' %not good align - set 0,1,2
%         'DND037' % different dir structure
%         'DND039'
%         'DND040' %not good align - set 0,1,2
%         'DND041' % different dir structure
%         'DND042' %not good align - set 0,1,2
%         'DND048' %not good align - set 0,1,2
%         'DND050' %not good align - set 0,1,2
%         'DND052' %not good align - set 0,1,2
%         'DND060'
%         'DND062' % different dir structure
        };
    tic;
    
    delete(gcp('nocreate'));
    nCores = feature('numcores');
    parpool(nCores);
    
    % Use multicore if available
    parfor ii=1:length(subjects)
        subject = subjects{ii};
        try
            switch stepName
                case 'ConvertNiiNew'
                    [dicomList, niiList, outputDir] = convert2NiiNew(dataDir, analysisDir, subject);
                    acqTimes = writeAcquisitionTimesFile(dicomList, outputDir, subject);
                    decayCorrectNiiVolumes(niiList, acqTimes, decayConstant);
                case 'Realign'
                    realignEstimateReslice(analysisDir, realignDirBase,  subject);
                    %Call FSL functions for
                case 'Coregister'
                    coregisterMeanPetWithT1(analysisDir, realignDirBase, mriDataDir, subject, t1Bet, petBet);
            end
            log(ii).message = [subject,' :: ','Preprocess successful'];
        catch err % on error collect log
            log(ii).message = [subject,' :: ***Preprocess FAILED ***', err.identifier,'::',err.message];
            log(ii).stack = char(join(cellfun(@(f,n,l) ...
                ['file: ',f(max(strfind(f,'/'))+1:end),' -function: ',n,' -line:',num2str(l)]...
                , {err.stack.file}', {err.stack.name}' ,{err.stack.line}','UniformOutput',false)...
                ,' ; '));
            cd(scriptdir);
            continue;
        end % end try/catch
    end % end parfor

    t=toc;
    disp('***Processing Summary****')
    for ii=1:length(log)
        disp('*********************************')
        disp(log(ii))
    end
    fprintf('Time to preProcess %d Subjects: %.3g seconds\n', ...
        length(subjects), t);
    fname=[analysisDir stepName 'log.mat'];
    save(fname, 'log');
end