% FID=Util_CheckFilename(FILENAME,TYPE)
%   This function checks the given filename for writing, and either prompts
%   the user to overwrite it, simply returns its state, or overwrites it
%   automatically.  When checking its state, the function outputs a number
%   respresenting the file state; otherwise, the file ID of the opened file
%   is returned.
%   
%   Input arguments:
%       FILENAME - the file to be checked, and possibly opened
%       TYPE - the file access option:  'w' to prompt for overwrite before
%           opening, 'wc' to return file state, or 'w-nocheck' to overwrite
%           without prompting.
%       
%   Output arguments;
%       FID - the file ID, or if TYPE='wc', the file state (2 - file exists,
%           1 - file doesn't exist, 0 - bad filename)
%
% Written by Alex Andrews, 2010?11.

function fid=Util_CheckFilename(sFilename,sType)

switch sType
    % If opening for writing, check whether file already exists
    case 'w'
        fid=fopen(sFilename,'r');
        if fid~=-1 
            fclose(fid);
            sInput=questdlg('File already exists.  Do you wish to overwrite?',...
                'Overwrite verification',...
                'Yes','No','No');
            if ~strcmp(sInput,'Yes')                
                fid=-1;
                fprintf('\n')
                return    
            end
        end
        % If filename is free for writing, check whether it is valid
        fid=fopen(sFilename,'w');
        if fid==-1
            Comm_Warn('File could not be opened for writing.');            
        end
        
    % If opening for writing, but want numeric result only
    case 'wc'
        fid=fopen(sFilename,'r');
        if fid~=-1 
            fclose(fid);
            fid=2; % 2 means that file already exists  
            return
        end
        % If filename is free for writing, check whether it is valid
        fid=fopen(sFilename,'w');
        if fid==-1
            fid=0; % 0 means that the filename is bad
        else
            fclose(fid);
            fid=1; % 1 means that the filename is good
        end
        
    % Don't check if file already exists     
    case 'w-nocheck'
        % heck whether it is valid
        fid=fopen(sFilename,'w');
        if fid==-1
            Comm_Warn('File could not be opened for writing.');            
        end        
    otherwise
        fid=-1;
end