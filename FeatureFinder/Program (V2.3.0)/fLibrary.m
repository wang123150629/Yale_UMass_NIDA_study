% Store and retrieve variables
function xBook=fLibrary(sVarName,xVarValue)

persistent stcLibrary

xBook=[];

% If no outputs and two inputs, set variable value
if nargout==0&&nargin==2
    stcLibrary.(sVarName)=xVarValue;
% If one output and one output, get variable name
elseif nargout==1&&nargin==1
    if isfield(stcLibrary,sVarName)
        xBook=stcLibrary.(sVarName);
    else
        fprintf('WARNING:  Variable not found in fLibrary (''%s'')\n\n',...
            sVarName);
    end
% If one input and no outputs, remove variable from libary
elseif nargout==0&&nargin==1
    if isfield(stcLibrary,sVarName)
        stcLibrary=rmfield(stcLibrary,sVarName);
    else
        %fprintf('NOTE:  Variable not found in fLibrary (''%s'')\n\n',...
        %    sVarName);  % suppress this warning (V2.3.0)
    end    
else
    fprintf('ERROR:  Unexpected input to fLibrary function (''%s'')\n\n',...
            sVarName);
end