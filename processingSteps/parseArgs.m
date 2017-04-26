function [opts] = parseArgs(opts, args)
%PARSEARGS Parse list of parameter-value pairs.
    if ~isstruct(opts) && ~isobject(opts), error('OPTS must be a structure') ; end
    if ~isstruct(args) && ~isobject(args), error('ARGS must be a structure') ; end
    
    optNames = fieldnames(opts)' ;
    %argument names/values
    params = fieldnames(args)' ;
    values = struct2cell(args)' ;
    for ind=1:numel(params)
        p = strcmpi(params{ind}, optNames);
        f = optNames{p};
        opts.(f)=values{ind};
    end
end