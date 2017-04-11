function [ fname ] = filecopy(fullFilePath, oDir)
%FILECOPY :
    if ~exist(oDir,'dir')
        mkdir(oDir);
    end
    [~,fn,ext]=fileparts(fullFilePath);
    fname=[fn ext];
    cmd=['cp ' fullFilePath ' ' oDir];
    disp(cmd);
    system(cmd, '-echo');
end
