function X=vObjects(A,B,C)

persistent Objects

X=[];

% Clear variable if requested
if nargin==1 && strcmp(A,'clear')
    clear Objects
% Set variable if requested
elseif nargin==2 && strcmp(A,'set')
    Objects=B;
% Retrieve variable if requested
elseif nargin==0
    X=Objects;
% If command not recognized, alert user
else
    fprintf('WARNING:  Unrecognized command to vObjects.\n\n');
end