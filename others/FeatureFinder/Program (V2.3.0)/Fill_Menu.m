% Fill_Menu(MENU_NAME,MENU_HANDLE)
%   Fill_Menu determines the items for the given menu, and then adds
%   them to the corresponding drop-down.
%   
%   Input arguments:
%       MENU_NAME - the name of the menu to be filled (e.g., 'Smooth',
%       'Feature')
%       MENU_HANDLES - the handle of the menu to be filled
%
%   Output arguments;
%       none
%
% Written by Alex Andrews, 2010-2012.

function Fill_Menu(sMenu,hdlMenu)

% Determine available methods
switch sMenu
    case 'Smooth'
        cObjects=Process_Filter('get_stypes');
    %case 'Feature'
    %    cObjects=Process_Feature('get_types');
    otherwise
        Comm_Warn('Invalid menu type passed to Fill_Menu')
        return
end

% Place available methods in given handles
set(hdlMenu,'String',cObjects);
set(hdlMenu,'Value',1);
