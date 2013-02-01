% Profile_UpdateLastSelected(WHICH,HANDLE)
%   This function stores the last selected values for all drop-down menus,
%   or just the menu specified by HANDLE.
%   
%   Input arguments:
%       WHICH - Either 'all' or 'this', depending on whether all menus are
%           to be saved or just the specified one.
%       HANDLE - The handle of the menu to be saved, for the case where 
%           WHICH='this', 
%       
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2011.

% NT:  remove WHICH, as it is redundant, and update all instances of
% function call

function Profile_UpdateLastSelected(sType,hObject)

cLastSelected=vLastSelected();

if isempty(cLastSelected)
    fprintf('WARNING:  cLastSelected is empty (Profile_UpdateLastSelected.\n\n');
    return
end

% If type is 'all,' then enter all current menu items into cLastSelected
if strcmpi(sType,'all')
    for i=1:size(cLastSelected,1)
        sObjectType=get(cLastSelected{i,1},'type');
        if strcmpi(sObjectType,'uicontrol')
            iVal=get(cLastSelected{i,1},'Value');
            cLastSelected{i,2}=iVal;
        elseif strcmpi(sObjectType,'uitable')
            nData=get(cLastSelected{i,1},'Data');
            cLastSelected{i,2}=nData;
        end
    end
% If type is 'this,' then enter only the menu item specified by hObject into cLastSelected    
elseif strcmpi(sType,'this')
    iRow=cell2mat(cLastSelected(:,1))==hObject;
    sObjectType=get(cLastSelected{iRow,1},'type');
    if strcmpi(sObjectType,'uicontrol')
        iVal=get(hObject,'Value');
        % If user unchecked current selection, recheck it
        if iVal==0
            set(hObject,'Value',cLastSelected{iRow,2});
        % Otherwise save new value to last-selected variable
        else
            cLastSelected{iRow,2}=iVal;   
        end
    elseif strcmpi(sObjectType,'uitable')
        nData=get(cLastSelected{iRow,1},'Data');      
        cLastSelected{iRow,2}=nData;         
    end
% If type is unrecognized, throw warning
else
    fprintf('WARNING:  Bad input argument to Profile_UpdateLastSelected function.\n\n')
    return
end

vLastSelected('set',cLastSelected);

