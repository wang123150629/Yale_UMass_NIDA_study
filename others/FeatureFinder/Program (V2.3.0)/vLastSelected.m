function X=vLastSelected(A,B,C)

persistent LastSelected

X=[];

% Clear variable if requested
if nargin==1 && strcmp(A,'clear')
    clear LastSelected
% Set variable if requested
elseif nargin==2 && strcmp(A,'set')
    LastSelected=B;
% Reset variable to initial values
elseif nargin==1 && strcmp(A,'reset')
    if ~isempty(LastSelected)
        LastSelected(:,2)={0};    
    end
% Retrieve variable if requested
elseif nargin==0
    X=LastSelected;
% If command not recognized, alert user
else
    fprintf('WARNING:  Unrecognized command to vLastSelected.\n\n');
end