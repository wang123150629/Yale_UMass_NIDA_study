% FILELIST=Util_FileLister(PATTERN)
%   This function seeks out all files that match the given pattern, then 
%   returns them as a cell with each file's parameter values.  Here is
%   an example of a function call:
%
%       FileLister('/Users/RussoG5/!/@-blk#-emo$-sen%.txt');
%   
%   Input arguments:
%       PATTERN - This is the file pattern that all the files
%           you are seeking must match.  There are six place holders
%           allowed:  !, @, #, $, %, and ^, and one wildcard:  *.
%   
%   Output arguments;
%       FILELIST - The cell is comprised of one column for filenames and
%           one column for each parameter containing the corresponding
%           parameter values for each file.
%
% Written by Alex Andrews, 2010?2012. 

function cFilesAndPars=Util_FileLister(sPattern)

% -------------------------
% -- 1.0  Setup function --
% -------------------------

sWildcard='*';
sMarkers='!@#$%^';
sAllPH=[sWildcard,sMarkers];
sGenMask=sPattern;
[a iPHs nPHs]=intersect(sGenMask,sAllPH);
sGenMask(iPHs)='*';
[temp b]=sort(iPHs);
iPHs=iPHs(b)';nPHs=nPHs(b)';
nNumMarkers=length(intersect([2:7],nPHs(nPHs~=1)));  % was setdiff
cFilesAndPars='';


% -----------------------
% -- 2.0  Check inputs --
% -----------------------

% 2.1  Check that pattern is valid
% Is there at least one placeholder?
if isempty(intersect(sPattern,sAllPH))
   %fprintf('ERROR:  No placeholders in pattern.\n\n')
   return
end
% Are there adjacent placeholders?
if any(diff(iPHs)==1)
    %fprintf('ERROR:  Adjacent placeholders.\n\n')
    return
end
% Are there backslashes?  Auto-convert to slashes
sGenMask(sGenMask=='\')='/';
sPattern(sPattern=='\')='/';


% -------------------------------------------
% -- 3.0 Find all files that match pattern --
% -------------------------------------------

% 3.1 Determine all possible search paths and corresponding parameters

% 3.1.2  Separate pattern into levels
%iPHs=find(sGenMask(:)==sWildcard);
iAllSlashes=find(sGenMask(:)=='/');
for i=1:length(iAllSlashes)+1
    if i==1
        iLevel(i,1:2)=[1 iAllSlashes(i)];        
    elseif i<=length(iAllSlashes)
        iLevel(i,1:2)=[iAllSlashes(i-1)+1 iAllSlashes(i)];        
    else
        iLevel(i,1:2)=[iAllSlashes(i-1)+1 length(sGenMask)];
    end
    cLevel{i}=sGenMask(iLevel(i,1):iLevel(i,2));
end
cLevel{end}=[cLevel{end},' '];

% 3.1.3  At each level, determine all possible filepaths
cRoots={''};
for i=1:length(cLevel)
    cNewRoots={};
    % If there are no wildcards, append to relevant entries
    if ~any(intersect(cLevel{i},sWildcard))
        if length(cRoots)==1
            cNewRoots={[cRoots{1},cLevel{i}]};
        else
            for j=1:length(cRoots)
                if exist([cRoots{j},cLevel{i}],'dir')||exist([cRoots{j},cLevel{i}],'file')
                    cNewRoots=[cNewRoots;[cRoots{j},cLevel{i}]];
                end
            end
        end
    else
        for j=1:length(cRoots)
            sContents=dir([cRoots{j},cLevel{i}(1:end-1)]);              
            % Put filepaths in file list variable
            for k=1:length(sContents)
                %If placeholder is not last one, remove any file entries
                if i<length(iAllSlashes)+1 % added one here to get working on mac?
                    if sContents(k).isdir==1&&~strcmp(sContents(k).name,'.')&&~strcmp(sContents(k).name,'..')
                        cNewRoots=[cNewRoots;[cRoots{j},sContents(k).name,'/']];
                    end
                else
                    if sContents(k).isdir==0
                        cNewRoots=[cNewRoots;[cRoots{j},sContents(k).name]];
                    end
                end
            end        
        end
    end
    cRoots=cNewRoots;
end


% --------------------------------------------
% -- 4.0 Determine parameters for each file --
% --------------------------------------------

% 4.1  Add virtual placeholder to character after end-of-file
iPHs=[iPHs;length(sPattern)+1];

% 4.2  Define variable to store placeholder information
cPH=cell(size(cRoots,1), length(sMarkers)+1);
if isempty(cRoots),return,end
cPH(:,1)=cRoots;
sFilelist=char(cRoots);
sFilelist(:,1:iPHs(1)-1)=[];
cFilelist=cellstr(sFilelist);

% 4.3  Extract parameters from filename
for i=1:length(iPHs)-1        
    if iPHs(i)<length(sPattern)
        % Extract text in between next two placeholders
        sChunk=sPattern(iPHs(i)+1:iPHs(i+1)-1);
        % Find next two instances of placeholders in mask, extract text in between
        cChunk=strfind(cFilelist,sChunk);
        iChunk=cellfun(@(x) x(1),cChunk);
    else
        iChunk=cellfun(@length,cFilelist)+1;
    end
    % If marker, store everything up to this location in parameter cell
    if nPHs(i)>1
        for j=1:size(cPH,1)
            cPH{j,nPHs(i)}=cFilelist{j}(1:iChunk(j)-1);
        end
    end
    
    % Remove everything up to next placeholder in file
    if iPHs(i)<length(sPattern)
        for j=1:size(cFilelist,1)
            cFilelist{j}(1:(iChunk(j)+length(sChunk)-1))=[];
        end
    end
end

% 4.4  Collapse unused columns
iUnused=setdiff(2:7,nPHs(nPHs~=1));
cPH(:,iUnused)=[];

% 4.5 Sort data so that strings of numbers are still sorted numerically
% (e.g., 1 2 3 4 ... not 1 10 11 2 3 ...)
for i=size(cPH,2):-1:2
    [~,nNumSorted]=Util_AlphaNumSort(cPH(:,i));
    cPH=cPH(nNumSorted,:);
end


% ------------------------------
% -- 5.0 Arrange data in call --
% ------------------------------

% 5.1  Setup output type
cFilesAndPars=cPH;