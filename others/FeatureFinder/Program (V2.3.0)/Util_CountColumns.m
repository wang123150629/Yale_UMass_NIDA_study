% COLS=Util_CountColumns(FILENAME,HLINES,DELIM)
%   This function returns the number of columns in the file specified by 
%   FILENAME.
%   
%   Input arguments:
%       FILENAME - the name of the file to have its columns counted.
%       HLINES - number of header lines in the file.
%       DELIM - delimiter used in between columns.
%   
%   Output arguments;
%       COLS - number of columns in the specified file
%
% Written by Alex Andrews, 2010.

function nNumCols=Util_CountColumns(sFilename,nHeaderLines,nDelim)

nNumCols=[];

% Extract first non-header line from file
fid=fopen(sFilename,'r');
if fid==-1    
    return
end
for i=1:nHeaderLines+1
    sFirstLine=fgetl(fid);
end

% Trim off whitespace at edges
sFirstLine=strtrim(sFirstLine);

% Use # of delimiters to calculate column number
iDelimPosn=find(sFirstLine==char(nDelim));
nNumCols=length(iDelimPosn)+1; 
fclose(fid);