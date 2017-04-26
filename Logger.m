classdef Logger < handle
    %LOGGER This is a simple logger based on Java Log4J Framework.
    %
    % Author:
    %       chenchal.subraveti@vanderbilt.edu
    % Inspiration:
    %       http://www.mathworks.com/matlabcentral/fileexchange/33532-log4matlab
    %
    
    properties (Constant)
        ALL = 0;
        TRACE = 1;
        DEBUG = 2;
        INFO = 3;
        WARN = 4;
        ERROR = 5;
        FATAL = 6;
        OFF = 7;
    end
    
    properties(Access = protected)
        logger;
        %lFile;
    end
    
    properties(SetAccess = protected)
        fullpath = 'logger.log';
        ConsoleLevel = Logger.ALL;
        logLevel = Logger.INFO;
    end
    
    methods (Static)
        function obj = getLogger(logPath)
            obj = Logger(logPath);
        end
    end
    
    
    %% Public methods
    methods
        function setFilename(self,logPath)            
            [fid,message] = fopen(logPath, 'a');
            if(fid < 0)
                error(['Error with path to logfile : ' message]);
            end
            fclose(fid);
            self.fullpath = logPath;
        end
        
        
        function setConsoleLevel(self,loggerIdentifier)
            self.ConsoleLevel = loggerIdentifier;
        end
        
        
        function setLogLevel(self,logLevel)
            self.logLevel = logLevel;
        end
        
        
        %% Logging utils
        function trace(self, message)
            self.log(self.TRACE,message);
        end
        
        function debug(self, message)
            self.log(self.DEBUG,message);
        end
        
        function info(self, message)
            self.log(self.INFO,message);
        end
        
        function warn(self, message)
            self.log(self.WARN,message);
        end
        
        function error(self, message)
            self.log(self.ERROR, message);
        end
        
        function fatal(self, message)
            self.log(self.FATAL,message);
        end
        
    end
    
    %% Private methods
    
    methods (Access = private)
        %ctor
        function self = Logger(loggerPath)
            self.setFilename(loggerPath);
        end
        %log writer
        function log(self,level,message)
           
            if isa(message,'MException')
                messageLines = createExceptionLogLines(level,message);
            else
                messageLines = createLogLine(level, message);              
            end
             % Log to console window
           if( self.ConsoleLevel <= level )
               for line = messageLines
                   fprintf('%s', char(line));
               end
            end
            
            %If currently set log level is too high, just skip this log
            if(self.logLevel > level)
                return;
            end           
            % Append new log to log file
            try
                fid = fopen(self.fullpath,'a');
                 for line = messageLines
                   fprintf(fid, '%s', char(line));
                 end
                fclose(fid);
            catch ME_1
                display(ME_1);
            end
            
            %%%% Nested functions%%%
            
            function [ levelStr ] = getLevelString(level)
                % set up our level string
                switch level
                    case{self.TRACE}
                        levelStr = 'TRACE';
                    case{self.DEBUG}
                        levelStr = 'DEBUG';
                    case{self.INFO}
                        levelStr = 'INFO';
                    case{self.WARN}
                        levelStr = 'WARN';
                    case{self.ERROR}
                        levelStr = 'ERROR';
                    case{self.FATAL}
                        levelStr = 'FATAL';
                    otherwise
                        levelStr = 'UNKNOWN';
                end
            end
            
            function [ lines ] = createExceptionLogLines(level, exObj)
                lines{1}=formatLogLine(level, exObj.identifier, strcat(exObj.identifier,'-',exObj.message));
                for i=1:numel(exObj.stack)
                    lines{end+1}=sprintf('\t\t%s > %s > %s\r\n'...
                        ,exObj.stack(i).file(max(strfind(exObj.stack(i).file,'/'))+1:end)...
                        ,exObj.stack(i).name...
                        ,num2str(exObj.stack(i).line));
                end
            end
            
            function [ lines ] = createLogLine(level, msgStr)
                [stkTrace,~]=dbstack();
                fx = stkTrace(4).name;
                lines{1} = formatLogLine(level, fx, msgStr);
            end
            
            function [ l ] = formatLogLine(level, fx, msgStr)
                levelStr = getLevelString(level);
                l = sprintf('%s|%s|%s|%s\r\n' ...
                    , datestr(now,'yyyy-mm-dd HH:MM:SS.FFF') ...
                    , levelStr ...
                    , fx ...
                    , msgStr);
            end
        end
    end
    
end

