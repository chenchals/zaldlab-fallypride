function [ fileList ] = getDicomFileList(filePathPattern)
%GETDICOMFILELIST Given a pattern of filepath returns a list of dicom files
%matching the pattern.
%
%   Inputs:
%   filepathPattern  : Pattern of the fullpath to files.
%     Example: '[dir]/Fallypride/Scan_1/DND005/Decay*/*DY*/*/3DFORE*'
%     matches all files in DY1, DY2, and DY2 sub folders with starting file
%     name of 3DFORE
%
%   Outputs:
%   fileList : A cell array of filenames (full path to the file):
%    Example: fileList: [1645×1 cell]
%
%   Example:
%   fileList =
%   GETDICOMFILELIST('[teba-location]/Scan_1/DND005/Decay*/*DY*/*/3DFORE*')
%   Note: the pattern may be different for exceptions for example see for
%   subjects : DND027, DND041, and DND060

%  Copyright 2016
%  Zald Lab, Department of Psychology, Vanderbilt University.
%
    dicomList=dir(filePathPattern);
    allFrames=num2cell(1:numel(dicomList));
    fileRef=@(x) {[dicomList(x(1)).folder,'/',dicomList(x(1)).name]};
    fileList = cellfun(fileRef, allFrames,'UniformOutput',false);
    fileList=[fileList{:}]';
    %Consider one liner
    %fList=arrayfun(@(x) [x.folder filesep x.name],dir(filePathPattern),'UniformOutput',false);
end
