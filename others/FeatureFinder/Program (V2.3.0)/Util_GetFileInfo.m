% [CHAN HEADERLINES DELIM PATTERN]=Util_GetFileInfo(FILENAME)
%   The Util_GetFileInfo function returns the number of channels,
%   headerlines, and delimiter string for the file with name FILENAME.
%   Several assumptions are made about the data file:
%       1.  The last line in the file contains a representative line of data
%       2.  The delimiter is either a comma, semicolon, tab, or space
%       3.  In a line of data, the number of delimiters exceeds the number
%           of any of the other candidate delimiters (commas, tabs, &c.)
%       4.  The first three lines of data have matching data types (i.e.,
%           number or string) and all have the correct number of channels.
%           Everything preceding this point is considered to be the header.   
%   
%   INPUTS:
%       FILENAME - the name of the file of which the number of channels,
%           number of headerlines, and delimiter string will be determined.
%
%   OUTPUTS:
%       CHAN - the number of channels in the data file
%       HEADERLINES - the number of headerlines in the data file
%       DELIM - the data file's delimiter string 
%       PATTERN - the pattern string to be used in file loading 
%           (e.g., %f%f%f)
%
%   Written by Alex Andrews, 2010?2011.


function [nNumChannels nHeaderLines sDelim sPattern]=Util_GetFileInfo(sDataFilename)

nNumChannels=[];
nHeaderLines=[];
sDelim='';
sPattern='';

% ---------------------------------------
% -- 1.0 Determine delimiter character --
% ---------------------------------------

% Check that file is a text file
if length(sDataFilename)<4||~strcmp(sDataFilename(end-3:end),'.txt')    
    return
end

% 1.1 Get second last line from given file
fid=fopen(sDataFilename);
if fid==-1,return,end
sTestLine=[];
i=0;
while (1==1)
    i=i+1;
    fseek(fid,-i,1);    
    fgetl(fid);
    fgetl(fid);
    if ~feof(fid)
        sTestLine=fgetl(fid);
        % If line is blank, try line above
        if all(sTestLine==' ')
            continue
        end
        break
    end
end
fclose(fid);
if isempty(sTestLine)
    fprintf('ERROR:  No linebreaks found in data file.\n\n');
    return
end

% 1.2 Determine number of commas, semicolons, tabs, and spaces in test line
nCommas=sum(sTestLine==',');
nSemicolons=sum(sTestLine==';');
nTabs=sum(sTestLine==char(9));
nSpaces=fGetGroupsOfSpaces(sTestLine,false,false);

switch max([nCommas,nSemicolons,nTabs,nSpaces])
    case nCommas
        sDelim=',';
    case nSemicolons
        sDelim=';';
    case nTabs
        sDelim=char(9);
    case nSpaces
        sDelim=' ';
end


% -----------------------------------
% -- 2.0 Determine no. of channels --
% -----------------------------------

% 2.1 Calculate number of channels
if strcmp(sDelim,' ')
    nNumChannels=nSpaces+1;
else
    nNumChannels=sum(sTestLine==sDelim)+1; 
end

% 2.2 Create pattern for future file loading
sPattern='';
for i=1:nNumChannels
    sPattern=[sPattern,'%s'];
end

% --------------------------------------
% -- 3.0 Determine no. of headerlines --
% --------------------------------------

% 3.1 Find first three lines with the expected number of delimiters
fid=fopen(sDataFilename);
c=0;
nGoodLine=0;
sThisPattern='';sLastPattern='';sPattern='';
while (1==1)
    c=c+1;
    
    % If line doesn't have the right # of delimiters, loop again
    sTestLine=fgetl(fid);
    if (strcmp(sDelim,' ') & fGetGroupsOfSpaces(sTestLine,false,false)~=nNumChannels-1) |...
            (~strcmp(sDelim,' ') & nNumChannels~=sum(sTestLine==sDelim)+1)
        sLastPattern='';
        nGoodLines=0;
        continue
    else
    % If line does have the right # of delimiters, determine data types
        sThisPattern=fGetPattern(sTestLine,sDelim);
        % Check whether data types match preceding line
        if strcmp(sThisPattern,sLastPattern)
            nGoodLines=nGoodLines+1;
        else
            sLastPattern=sThisPattern;
            nGoodLines=0;
            continue
        end    
    end        
    
    % If three lines in a row with same data types, assume header found
    if nGoodLines==2
        nHeaderLines=c-3;
        sPattern=sLastPattern;
        break
    end    
           
    % If end-of-file reached, return error
    if feof(fid)
        nHeaderLines=-1;
        fprintf('ERROR:  Error determining # of headerlines.\n\n');
        break
    end       
end
fclose(fid);

function nSpaces=fGetGroupsOfSpaces(sString,bIncludeLeading,bIncludeTrailing)


% Count adjacent spaces as one, and ignore leading and trailing spaces
nSpaces=0;
if ~isempty(sString)
    iSpaces=sString==' ';
else
    return
end

for i=2:length(iSpaces)
   if (iSpaces(i-1)==1&&iSpaces(i)==0)
       nSpaces=nSpaces+1;
   end
end

% Correct for leading spaces
if iSpaces(1)==1 & ~all(iSpaces) & ~bIncludeLeading
    nSpaces=nSpaces-1;
end 

% Correct for trailing spaces
if iSpaces(end)==1 & bIncludeTrailing
    nSpaces=nSpaces+1;
end

% In case the string is all spaces, correct estimate
if all(iSpaces) & (bIncludeLeading | bIncludeTrailing)
   nSpaces=1; 
end




function sPattern=fGetPattern(sTestLine,sDelim)

% Extract each field of string
nDelimPos=find(sTestLine==sDelim);
nDelimPos(end+1)=length(sTestLine)+1;
nNextStringStart=1;
cSubString=cell(length(nDelimPos),1);
for i=1:length(nDelimPos)
    cSubString{i}=sTestLine(nNextStringStart:nDelimPos(i)-1);
    nNextStringStart=nDelimPos(i)+1;
end

% Determine whether each field is a number of string, and build pattern
sPattern='';
for i=1:length(cSubString)
    sTest=cSubString{i};
    if ~isnan(str2double(sTest))
        sPattern=[sPattern,'%f'];
    else
        sPattern=[sPattern,'%s'];
    end
end