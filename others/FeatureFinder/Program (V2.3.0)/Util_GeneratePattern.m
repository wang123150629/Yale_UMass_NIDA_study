% PATTERN=Util_GeneratePattern(COLS,TYPE,DELIM,EOL)
%   This function generates a pattern string to be used with low-level
%   file I/O functions such as fprintf and textscan.  Patterns can also 
%   be used with other similar functions, such as sprintf.
%   
%   Input arguments:
%       COLS - the number of columns of data 
%       TYPE - the data type to be written to file (e.g., '%s')
%       DELIM - the delimiting character to use (e.g., '\t' or 9)
%       EOL - the end-of-line character to use (for none, input '')
%   
%   Output arguments:
%       PATTERN - the pattern string to be used in low-level file I/O or
%           related functions
%
% Written by Alex Andrews, 2010?2011.


function sPattern=Util_GeneratePattern(nCols,sType,sDelim,sEOL)

% Convert delimiter and end-of-line to char, if necessary
if isnumeric(sDelim)
    switch sDelim    
        case 9
            sDelim='\t';
        case 32
            sDelim=' ';
        otherwise
            fprintf(['ERROR:  Unrecognized delimiter number input ',...
                'to Util_GeneratePattern.\n\n']);
    end
end
if isnumeric(sEOL)
    switch sEOL    
        case 9
            sEOL='\t';
        case 10
            sEOL='\n';
        case 32
            sEOL=' ';        
        otherwise
            fprintf(['ERROR:  Unrecognized EOL number input ',...
                'to Util_GeneratePattern.\n\n']);
    end
end

% Initialize pattern string
sPattern=sType;

% Add type and delimiter for each subsequent column
for i=2:nCols
    sPattern=[sPattern,sDelim,sType];
end

% Append end-of-line character
sPattern=[sPattern,sEOL];