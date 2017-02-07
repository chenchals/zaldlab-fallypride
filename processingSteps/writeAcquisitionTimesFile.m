function [ acqTimes ] = writeAcquisitionTimesFile(dicomList, outputDir, subject)
%WRITEACQUISITIONTIMESFILE Returns a struct of aqusition times of PET images,
%given list of dicom files.
%This Acqusition time file can be imported into PMOD.
%
%   Inputs:
%   dicomList  : List of dicom files.
%     Checks if all files belong to the same subject.
%     Checks if the length of dicomList is a multiple of 47 (47 slices /
%     vol).
%   outputBaseDir : Output base directory where processed files are written.
%   subject : Subject ID.  Example: 'DND005'
%
%   Outputs:
%   Writes output file [outputDir]/[subject]_acquisitionTimes.acqtimes
%    Example: processedDir/test/DND005_acquisitionTimes.acqtimes
%   aqTimes : struct with fields:
%    Example: DND005: [35×2 double]
%
%   Example:
%   aqTimes = WRITEACQUISITIONTIMESFILE({'file1.dcm','file2.dcm',..},...
%                                     'processedDir/test', 'DND005');

%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%

    % Check for number of files and if files belong to the same subject
    nFramesPerVolume=47;
    if (...
            rem(length(dicomList), nFramesPerVolume) ~= 0 || ...
            ((nFramesPerVolume*35) ~= sum(cellfun(@(f, s) contains(f, s)...
            , dicomList,repmat({['/',subject,'/']},length(dicomList),1))))...
            )
        ME = MException(['Number of files in the dicom list must be a multiple of nFramesPerVolume [',num2str(nFramesPerVolume),']. '...
            'All dicom files must belong to the same subject [',subject,']. '...
            'The total number of DICOM files expected was not equal to 35*47' ]);
        throw(ME);
    end

    acqTimes = lookupAcqisitionTimes(dicomList, nFramesPerVolume);
    writePmodTimingFile(outputDir, subject, acqTimes);

end

%%
function [ acqTimes ] = lookupAcqisitionTimes(dicomList, nFramesPerVolume)
    volumeEndFrames=num2cell(nFramesPerVolume:nFramesPerVolume:length(dicomList));
    fileRef=@(x) {dicomList(x(1))};
    filelist = cellfun(fileRef, volumeEndFrames,'UniformOutput',false);

    %acqTimeRef is a matrix of [HHMMSS.S timeInSecs frameDurationSecs]
    acqTimeRef=cellfun(@getVolumeTimes,filelist,'UniformOutput',false);

    acqTimeRef=acqTimeRef';
    acqTimeRef=cell2mat(acqTimeRef);
    acqTimeRef=sortrows(acqTimeRef,1);
    % Compute time offset for DY2 volumes
    % offsetDY2 = vol29AcqTime - (vol28AcqTime + vol28ActualFrameDuration)
    offsetDY2=acqTimeRef(29,2)-(acqTimeRef(28,2)+acqTimeRef(28,3));
    % offsetDY3 = vol33AcqTime - (vol32AcqTime + vol32ActualFrameDuration) + offsetDY2
    offsetDY3=acqTimeRef(33,2)-(acqTimeRef(32,2)+acqTimeRef(32,3))+offsetDY2;
    acqTimeRef(:,4)=cumsum(acqTimeRef(:,3));
    % Create ends
    acqTimes(1:28,2)=acqTimeRef(1:28,4);
    acqTimes(29:32,2)=acqTimeRef(29:32,4)+offsetDY2;
    acqTimes(33:35,2)=acqTimeRef(33:35,4)+offsetDY3;
    % Create starts by subtracting frame times
    acqTimes(:,1)=acqTimes(:,2)-acqTimeRef(:,3);
end

%%
function [ atSE ] = getVolumeTimes(dicomStartEndFiles)
    %
    % Return: [HHMMSS.S timeInSecs frameDurationSecs]
    file=dicomStartEndFiles{1};
    if (iscell(file))
        file=file{1};
    end
    info=dicominfo(file);
    aqTime=info.AcquisitionTime;
    atSE=[str2double(aqTime),acqusitionTimeToSec(aqTime),info.ActualFrameDuration/1000.0];
end

%%
function [ secs ] = acqusitionTimeToSec(dicomAcquisitionTime)
    %format is always HHMMSS.S
    secs=str2double(dicomAcquisitionTime(1:2))*60*60;
    secs=secs+str2double(dicomAcquisitionTime(3:4))*60;
    secs=secs+str2double(dicomAcquisitionTime(5:end));
end

%%
function writePmodTimingFile(oDir,subject,acqTimes)
    %
    resultDir=[oDir,filesep,];
    if (~isdir(resultDir))
        mkdir(resultDir);
    end
    fname=[resultDir,subject,'_acquisitionTimes.acqtimes'];
    fid=fopen(fname, 'w');
    nVols=size(acqTimes,1);
    fprintf(fid, '# Acquisition times (start end)in seconds\n');
    fprintf(fid, '%d # Number of acquisitions\n', nVols);
    for ii=1:size(acqTimes,1)
        fprintf(fid,'%0.1f\t%0.1f\n',acqTimes(ii,:));
    end
    fclose(fid);
    disp(['Wrote timing file : ',fname]);
end