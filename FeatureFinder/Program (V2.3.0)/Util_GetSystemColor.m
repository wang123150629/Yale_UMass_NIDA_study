function nColor=Util_GetSystemColor(hFigure)

try
    nColor=get(hFigure,'factoryUicontrolBackgroundColor');
catch sError
    nColor=[0.9294 0.9294 0.9294];
    fprintf('NOTE:  Could not access default background colours.\n\n');
end
if mean(nColor)<0.85,nColor=[0.9294 0.9294 0.9294];end