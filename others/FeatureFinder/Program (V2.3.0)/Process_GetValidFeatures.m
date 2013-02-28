% FEATURES=Process_GetValidFeatures()
%   The Process_GetValidFeatures function searches the "Features" directory
%   for feature scripts, and tests those it finds.  Features scripts that
%   execute without error on test data and return a numeric, scalar value
%   are returned.
%   
%   Input arguments:
%       none
%   
%   Output arguments;
%       FEATURES - A cell containing the names of all valid features
%
% Written by Alex Andrews, 2011.

function cFeatures=Process_GetValidFeatures()

cFeatures={};
sPaths=vPaths();

% Get filenames of all m-files in directory
sFiles=dir(sPaths.Features);
c=1;
while c<=length(sFiles)
    [~,sName,sExt]=fileparts(sFiles(c).name);
    if ~strcmpi(sExt,'.m')
        sFiles(c)=[];
    elseif strcmpi(sName,'FeatureTemplate')
        sFiles(c)=[];
    else
        c=c+1;
    end
end

% Test each script found
Fs=1000;
T=2*Fs;
nData=randn(T,1)+sin(2*pi*0.5*[1:T]./Fs)';
nBL_Range=[1:floor(T/2)];
nTarg_Range=[ceil(T/2):T];
iNextFeature=0;
fprintf(' __________________\n|\n');
fprintf('| TESTING FEATURES\n');
fprintf('|   If the testing of a feature takes a long time, \n');
fprintf('|   there may be an error in your feature''s code. \n');
fprintf('|   Press CTRL-c to attempt a force quit, fix the \n');
fprintf('|   problem feature, and then try again!\n|\n');
fprintf('|   NOTE:  Calculation times are for %0.1f s of data \n',T/Fs);
fprintf('|          (a noisy sinusoid).\n|\n\n');
if isempty(sFiles)
    fprintf('NO FEATURES FOUND\n');
    fprintf('Please ensure valid feature files exist in the \n');
    fprintf('features directory and try again.\n');
    fprintf('%s%s\n\n',sPaths.Features);
    return
end
for i=1:length(sFiles)
    % Specify which feature is being tested, so that user can break in case of
    % infinite loop
    fprintf('Testing %s...\n',sFiles(i).name);
    
    % Extract feature from test data
    tic;
    [nFeature bCrash]=Util_ExternalFcn(sPaths.Features,sFiles(i).name(1:end-2),...
            {nData,Fs,nBL_Range,nTarg_Range});
    nCalcTime=toc;
    
    % Check feature for errors
    if bCrash
        fprintf('   ...feature not added (yielded error).\n\n');
    else
        %if isempty(nFeature) (commented out for V2.3.0)
        %    fprintf('   ...feature not added (yielded empty value).\n\n')  
        %else
        if ~isnumeric(nFeature)
            fprintf('   ...feature not added (yielded non-numeric feature).\n\n')  
        %elseif numel(nFeature)>1  (commented out for V2.3.0)
        %    fprintf('   ...feature not added (yielded multidimensional value).\n\n')          
        else
            fprintf('   ...feature added (%0.3f s).\n\n',nCalcTime)  
            iNextFeature=iNextFeature+1;
            [~,cFeatures{iNextFeature},~]=fileparts(sFiles(i).name);
        end
    end
end


