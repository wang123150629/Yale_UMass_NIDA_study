function X=vPaths(A,B,C)

persistent Paths

X=[];

% Clear variable if requested
if nargin==1 && strcmp(A,'clear')
    clear Paths
% Set variable if requested
elseif nargin==2 && strcmp(A,'set')
    Paths=B;
% Retrieve variable if requested
elseif nargin==0
    X=Paths;
% If command not recognized, alert user
else
    fprintf('WARNING:  Unrecognized command to vPaths.\n\n');
end