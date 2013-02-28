% FILTERS=Process_GetValidFilters()
%   The Process_GetValidFilters function searches the "Filters" directory
%   for filter scripts, and tests those it finds.  The function returns
%   the names of all filters that execute without error on test data and 
%   return a numeric vector of the same length.
%   
%   Input arguments:
%       none
%   
%   Output arguments;
%       FILTERS - A cell containing the names of all valid filters
%
% Written by Alex Andrews, 2011?2012.

function cFilters=Process_GetValidFilters()

cFilters={'none'};
sPaths=vPaths();

% Get filenames of all m-files in filters directory
sFiles=dir(sPaths.Filters);
c=1;
while c<=length(sFiles)
    [~,sName,sExt]=fileparts(sFiles(c).name);
    if ~strcmpi(sExt,'.m')
        sFiles(c)=[];
    elseif strcmpi(sName,'FilterTemplate')
        sFiles(c)=[];
    else
        c=c+1;
    end
end

% Test each script found
Fs=1000;
T=2*Fs;
nData=randn(T,1)+sin(2*pi*0.5*[1:T]./Fs)';
iNextFilter=1;
fprintf(' __________________\n|\n');
fprintf('| TESTING FILTERS\n');
fprintf('|   If the testing of a filter takes a long time, \n');
fprintf('|   there may be an error in your filter''s code. \n');
fprintf('|   Press CTRL-c to attempt a force quit, fix the \n');
fprintf('|   problem filter, and then try again!\n|\n');
fprintf('|   NOTE:  Calculation times are for %0.1f s of data \n',T/Fs);
fprintf('|          (a noisy sinusoid).\n|\n\n');
if isempty(sFiles)
    fprintf('NO FILTERS FOUND\n');
    fprintf('Please ensure valid filter files exist in the \n');
    fprintf('filters directory and try again.\n');
    fprintf('%s%s\n\n',sPaths.Filters);
    return
end
for i=1:length(sFiles)
    % Specify which filter is being tested, so that user can break in case of
    % infinite loop
    fprintf('Testing %s...\n',sFiles(i).name);
    
    % Filter test data
    tic;
    [nFiltered bCrash]=Util_ExternalFcn(sPaths.Filters,sFiles(i).name(1:end-2),...
            {nData,Fs});
    nCalcTime=toc;
    
    % Check filtered data for errors
    if bCrash
        fprintf('   ...filter not added (yielded error).\n\n');
    else
        if isempty(nFiltered)
            fprintf('   ...filter not added (yielded empty value).\n\n')  
        elseif ~isnumeric(nFiltered)
            fprintf('   ...filter not added (yielded non-numeric values).\n\n')  
        elseif numel(nFiltered)~=numel(nData)
            fprintf('   ...filter not added (yielded different size than raw data).\n\n')  
        else
            fprintf('   ...filter added (%0.3f s).\n\n',nCalcTime)  
            iNextFilter=iNextFilter+1;
            [~,cFilters{iNextFilter},~]=fileparts(sFiles(i).name);
        end
    end
end


