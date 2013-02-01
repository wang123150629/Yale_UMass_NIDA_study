function bCompatible=Util_CheckCompatibilty()

% Set default value
bCompatible=true;

% Check that MATLAB version is 2009a or newer
nVer=sscanf(version,'%d.%d');
if nVer(1)<7||(nVer(1)==7&&nVer(2)<8)
    bCompatible=false;
    Comm_Warn(['FeatureFinder requires MATLAB 7.8 (2009a) or later.  ',...
        'Please upgrade and try again.']);
    
% Determine whether the 'butter' function is available
elseif ~exist('butter')
    bCompatible=false;
    Comm_Warn(['The function ''butter'' could not be found.  Please ',...
        'ensure that the Signal Processing Toolbox is correctly installed.']);
end