function Profile_RevertLastSelected()

cLastSelected=vLastSelected();

% Retrieve GUI object information
cObjects=vObjects();

% Loop through each object and change value to that which was last selected
for i=1:size(cLastSelected,1)
    sObjectTag=get(cLastSelected{i,1},'Tag');
    if strcmpi(sObjectTag,'tblWindows')
        set(cLastSelected{i,1},'Data',cLastSelected{i,2});
    else
        set(cLastSelected{i,1},'Value',cLastSelected{i,2});
    end        
end
Profile_SaveGUI(cObjects.ProfileMenu);
