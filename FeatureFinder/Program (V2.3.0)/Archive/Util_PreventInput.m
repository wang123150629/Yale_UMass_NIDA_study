% Create a hidden window to take the focus
function Util_PreventInput(bType)

if bType
    figure('Tag','PreventInput','Position',[-400 -400 1 1],...
        'WindowStyle','modal')
else    
    h=findobj('Tag','PreventInput');
    delete(h);
end