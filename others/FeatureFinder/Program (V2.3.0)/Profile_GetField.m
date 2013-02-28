% FIELD=Profile_GetField(FIELDNAME,CONVERT)
%   This function returns the field value(s) specified by FIELDNAME from 
%   the current profile.  The FIELDNAME parameter can be a cell of multiple
%   strings, in which case the function will return a cell of the same 
%   size.
%   
%   Input arguments:
%       FIELDNAME - The name of the field(s) from which values are to be
%           returned.  This can be a cell of any size, e.g., {'Lucy'} or
%           {'Gabe','Lisa','Alex'}
%       CONVERT - Fields are extracted to a string variable by default,
%           though several conversion options are available:  to_bool, 
%           to_num, and to_string.
%
%   Output arguments:
%       FIELD - The value(s) from the field(s) specified by FIELDNAME.
%       
%
% Written by Alex Andrews, 2011.

function cField=Profile_GetField(cFieldname,cConvert)

sPaths=vPaths();

% If cFilename is a string, convert to cell
if ~iscell(cFieldname)
    cFieldname={cFieldname};
end

% If cConvert is a string, convert to cell
if ~iscell(cConvert)
    cConvert={cConvert};
end

% Check that cConvert length is either the same as cFieldname or one
if nargin==2
    if length(cConvert)~=length(cFieldname)&&length(cConvert)~=1
        Comm_Warn('Bad dimension of conversion argument passed to Profile_GetField');
        return
    end
elseif nargin==0
    Comm_Warn('Not enough input arguments to Profile_GetField.');
    return
else
    cConvert{1}='to_string';
end

% If cConvert is of length 1, expand to size of cFieldname
if length(cConvert)==1
    cConvert(1:length(cFieldname))=cConvert(1);    
end

% If cConvert consists of all bool or all num values, note for later 
% cell-to-matrix conversion
if all(strcmpi(cConvert,'to_num'))||all(strcmpi(cConvert,'to_bool'))
    bConvertToMatrix=true;
else
    bConvertToMatrix=false;
end
        
% Open profile file
% Profile_Settings=Profile_GetSettings(sProfile);
thisProfile=vCurrentProfile();
Profile_Settings=thisProfile.propertyList;
if ~isempty(thisProfile.dataSettings)
    if ~isempty(thisProfile.getChannel)
        Data_Settings=thisProfile.dataSettings{thisProfile.getChannel};
    else
        fprintf('No channel value stored (Profile_GetField)!\n\n');
        return
    end
else
    Data_Settings={'',''};
end

% Loop through all given field names
cField=cell(length(cFieldname),1);
for i=1:length(cFieldname)
    % Check Profile and Data settings for desired field
    iInPS=strcmpi(Profile_Settings(:,1),cFieldname{i});  
    iInDS=strcmpi(Data_Settings(:,1),cFieldname{i});  
    if any(iInPS)&any(iInDS)
        fprintf('WARNING:  Redundancy found in settings\n\n');
        % Retrieve desired field
        cField{i}=fConvert(Profile_Settings{iInPS,2},cConvert{i});
    elseif any(iInPS)
        % Retrieve desired field
        cField{i}=fConvert(Profile_Settings{iInPS,2},cConvert{i});
    elseif any(iInDS)
        % Retrieve desired field
        cField{i}=fConvert(Data_Settings{iInDS,2},cConvert{i});
    else
        fprintf(['WARNING:  Field name not found! (',cFieldname{i},')\n\n']);
        cField{i}=fConvert('',cConvert{i});
    end
    
    
    %if isempty(cField{i})  gives errror when field is empty (not desired,
    %so commented)
    %    Comm_Warn('Bad conversion argument value passed to Profile_GetField. Data not found.');
    %end
end

% If single value returned, remove from cell
if length(cField)==1
    cField=cField{1};
% Otherwise, convert to matrix if all numeric or all boolean values
elseif bConvertToMatrix
    cField=cell2mat(cField);
end

function xField=fConvert(sField,sConvert)

% Convert input argument value to form specified by sConvert
switch sConvert
    case 'to_bool'
        xField=logical(str2num(sField));
    case 'to_num'
        xField=str2num(sField);
    case 'to_string'
        xField=sField;
    otherwise
        xField=[];        
end 
