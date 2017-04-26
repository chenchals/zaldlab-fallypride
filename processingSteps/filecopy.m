function [ fname ] = filecopy(fullFilePath, oDir)
%FILECOPY :
    if ~exist(oDir,'dir')
        mkdir(oDir);
    end

    if ischar(fullFilePath)
        fullFilePath = {fullFilePath};
    end
    for ii = 1:numel(fullFilePath)
        [~,fn,ext]=fileparts(fullFilePath{ii});
        fname{ii}=[fn ext];
        cmd=['cp ' fullFilePath{ii} ' ' oDir];
        disp(cmd);
        system(cmd, '-echo');
    end
    
    if numel(fname) == 1
        fname = char(fname);
    end
    
end
